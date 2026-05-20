package com.studycompanion.controller;

import com.studycompanion.dto.*;
import com.studycompanion.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<MfaPendingResponse> register(@Valid @RequestBody AuthRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }

    /** Step 1 — validate password, send OTP email, return pending token. */
    @PostMapping("/login")
    public ResponseEntity<MfaPendingResponse> login(@Valid @RequestBody AuthRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    /** Step 2 — submit the 6-digit OTP; receive full access + refresh tokens. */
    @PostMapping("/mfa/verify")
    public ResponseEntity<AuthResponse> verifyMfa(@Valid @RequestBody MfaVerifyRequest request) {
        return ResponseEntity.ok(authService.verifyMfa(request.getPendingToken(), request.getOtp()));
    }

    /** Resend a new OTP for an existing pending session. */
    @PostMapping("/mfa/resend")
    public ResponseEntity<Map<String, String>> resendOtp(@RequestBody Map<String, String> body) {
        String pendingToken = body.get("pendingToken");
        if (!StringUtils.hasText(pendingToken)) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "pendingToken is required"));
        }
        authService.resendOtp(pendingToken);
        return ResponseEntity.ok(Map.of("message", "Verification code resent to your email."));
    }

    @PostMapping("/refresh")
    public ResponseEntity<AuthResponse> refresh(@Valid @RequestBody RefreshRequest request) {
        return ResponseEntity.ok(authService.refresh(request.getRefreshToken()));
    }

    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logout(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestBody(required = false) LogoutRequest request) {
        String accessToken = null;
        if (StringUtils.hasText(authHeader) && authHeader.startsWith("Bearer ")) {
            accessToken = authHeader.substring(7);
        }
        String refreshToken = (request != null) ? request.getRefreshToken() : null;
        authService.logout(accessToken, refreshToken);
        return ResponseEntity.ok(Map.of("message", "Logged out successfully"));
    }

    @GetMapping("/validate")
    public ResponseEntity<Map<String, String>> validate(
            @RequestHeader("Authorization") String authHeader) {
        return ResponseEntity.ok(Map.of("status", "valid"));
    }
}
