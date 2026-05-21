package com.studycompanion.service;

import com.studycompanion.dto.AuthRequest;
import com.studycompanion.dto.AuthResponse;
import com.studycompanion.dto.LoginRequest;
import com.studycompanion.dto.MfaPendingResponse;
import com.studycompanion.model.MfaOtp;
import com.studycompanion.model.RefreshToken;
import com.studycompanion.model.RevokedToken;
import com.studycompanion.model.User;
import com.studycompanion.repository.MfaOtpRepository;
import com.studycompanion.repository.RefreshTokenRepository;
import com.studycompanion.repository.RevokedTokenRepository;
import com.studycompanion.repository.UserRepository;
import com.studycompanion.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.Date;
import java.util.HexFormat;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final RefreshTokenRepository refreshTokenRepository;
    private final RevokedTokenRepository revokedTokenRepository;
    private final MfaOtpRepository mfaOtpRepository;
    private final EmailService emailService;

    @Value("${app.jwt.refresh-token-expiry-days}")
    private int refreshTokenExpiryDays;

    @Value("${app.mfa.otp-expiry-minutes}")
    private int otpExpiryMinutes;

    @Value("${app.mfa.otp-max-attempts}")
    private int otpMaxAttempts;

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    // ── Registration ───────────────────────────────────────────────────────

    public MfaPendingResponse register(AuthRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Registration failed. Please check your details and try again.");
        }
        User user = new User();
        user.setEmail(request.getEmail().toLowerCase().trim());
        user.setName(request.getName());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setEmailVerified(false);
        user = userRepository.save(user);

        String otp = generateAndStoreOtp(user.getId());
        emailService.sendOtp(user.getEmail(), user.getName(), otp);

        String pendingToken = tokenProvider.generatePendingMfaToken(user.getId());
        return new MfaPendingResponse(true, pendingToken, maskEmail(user.getEmail()));
    }

    // ── Login — verify password, issue tokens directly ────────────────────

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail().toLowerCase().trim())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials"));
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials");
        }

        String accessToken = tokenProvider.generateAccessToken(user.getId());
        String refreshToken = issueRefreshToken(user.getId());
        return new AuthResponse(accessToken, refreshToken, user.getId(), user.getEmail(), user.getName());
    }

    // ── Login — step 2: verify OTP, issue tokens ──────────────────────────

    public AuthResponse verifyMfa(String pendingToken, String otp) {
        String userId = tokenProvider.getUserIdFromPendingMfaToken(pendingToken);

        MfaOtp stored = mfaOtpRepository
                .findFirstByUserIdAndUsedFalseOrderByExpiresAtDesc(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                        "No active verification code. Please request a new one."));

        if (stored.getExpiresAt().before(new Date())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Verification code has expired. Please request a new one.");
        }

        if (stored.getFailedAttempts() >= otpMaxAttempts) {
            mfaOtpRepository.delete(stored);
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Too many incorrect attempts. Please request a new verification code.");
        }

        if (!sha256(otp).equals(stored.getOtpHash())) {
            stored.setFailedAttempts(stored.getFailedAttempts() + 1);
            if (stored.getFailedAttempts() >= otpMaxAttempts) {
                mfaOtpRepository.delete(stored);
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                        "Too many incorrect attempts. Please request a new verification code.");
            }
            mfaOtpRepository.save(stored);
            int remaining = otpMaxAttempts - stored.getFailedAttempts();
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Incorrect verification code. " + remaining + " attempt" + (remaining == 1 ? "" : "s") + " remaining.");
        }

        stored.setUsed(true);
        mfaOtpRepository.save(stored);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"));

        if (!user.isEmailVerified()) {
            user.setEmailVerified(true);
            userRepository.save(user);
        }

        String accessToken = tokenProvider.generateAccessToken(userId);
        String refreshToken = issueRefreshToken(userId);
        return new AuthResponse(accessToken, refreshToken, user.getId(), user.getEmail(), user.getName());
    }

    // ── Resend OTP (same pending token, new code) ──────────────────────────

    public void resendOtp(String pendingToken) {
        String userId = tokenProvider.getUserIdFromPendingMfaToken(pendingToken);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"));

        String otp = generateAndStoreOtp(userId);
        emailService.sendOtp(user.getEmail(), user.getName(), otp);
    }

    // ── Token refresh ─────────────────────────────────────────────────────

    public AuthResponse refresh(String rawRefreshToken) {
        String hash = sha256(rawRefreshToken);
        RefreshToken stored = refreshTokenRepository.findByTokenHash(hash)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid refresh token"));

        if (stored.isRevoked() || stored.getExpiresAt().before(new Date())) {
            refreshTokenRepository.deleteByUserId(stored.getUserId());
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Refresh token is invalid or expired");
        }

        stored.setRevoked(true);
        refreshTokenRepository.save(stored);

        String newAccessToken = tokenProvider.generateAccessToken(stored.getUserId());
        String newRefreshToken = issueRefreshToken(stored.getUserId());

        User user = userRepository.findById(stored.getUserId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"));
        return new AuthResponse(newAccessToken, newRefreshToken, user.getId(), user.getEmail(), user.getName());
    }

    // ── Logout ─────────────────────────────────────────────────────────────

    public void logout(String currentAccessToken, String rawRefreshToken) {
        if (currentAccessToken != null && tokenProvider.validateToken(currentAccessToken)) {
            String jti = tokenProvider.getJtiFromToken(currentAccessToken);
            Date expiry = tokenProvider.getExpirationFromToken(currentAccessToken);
            if (!revokedTokenRepository.existsByJti(jti)) {
                revokedTokenRepository.save(new RevokedToken(jti, expiry));
            }
        }
        if (rawRefreshToken != null && !rawRefreshToken.isBlank()) {
            String hash = sha256(rawRefreshToken);
            refreshTokenRepository.findByTokenHash(hash).ifPresent(rt -> {
                rt.setRevoked(true);
                refreshTokenRepository.save(rt);
            });
        }
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    private String generateAndStoreOtp(String userId) {
        // Replace any existing OTP for this user
        mfaOtpRepository.deleteByUserId(userId);

        // Cryptographically random 6-digit code
        int code = 100_000 + SECURE_RANDOM.nextInt(900_000);
        String otp = String.valueOf(code);

        MfaOtp mfaOtp = new MfaOtp();
        mfaOtp.setUserId(userId);
        mfaOtp.setOtpHash(sha256(otp));
        mfaOtp.setUsed(false);
        mfaOtp.setExpiresAt(Date.from(Instant.now().plus(otpExpiryMinutes, ChronoUnit.MINUTES)));
        mfaOtpRepository.save(mfaOtp);

        return otp;
    }

    private String issueRefreshToken(String userId) {
        byte[] bytes = new byte[32];
        SECURE_RANDOM.nextBytes(bytes);
        String rawToken = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        String hash = sha256(rawToken);

        RefreshToken rt = new RefreshToken();
        rt.setTokenHash(hash);
        rt.setUserId(userId);
        rt.setRevoked(false);
        rt.setExpiresAt(Date.from(Instant.now().plus(refreshTokenExpiryDays, ChronoUnit.DAYS)));
        refreshTokenRepository.save(rt);

        return rawToken;
    }

    static String maskEmail(String email) {
        int at = email.indexOf('@');
        if (at <= 0) return "***@***";
        String local = email.substring(0, at);
        String domain = email.substring(at);
        if (local.length() <= 2) return local.charAt(0) + "**" + domain;
        return local.charAt(0) + "***" + local.charAt(local.length() - 1) + domain;
    }

    static String sha256(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(input.getBytes());
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }
}
