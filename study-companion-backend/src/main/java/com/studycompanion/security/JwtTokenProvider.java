package com.studycompanion.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.UUID;

@Component
public class JwtTokenProvider {

    private static final String MFA_PURPOSE = "mfa-pending";

    private final SecretKey key;
    private final long accessTokenExpiryMs;
    private final long pendingMfaTokenExpiryMs;
    private final String issuer;
    private final String audience;

    public JwtTokenProvider(
            @Value("${app.jwt.secret}") String secret,
            @Value("${app.jwt.access-token-expiry-ms}") long accessTokenExpiryMs,
            @Value("${app.jwt.pending-mfa-token-expiry-ms}") long pendingMfaTokenExpiryMs,
            @Value("${app.jwt.issuer}") String issuer,
            @Value("${app.jwt.audience}") String audience) {
        // Enforce minimum 32-byte (256-bit) secret for HMAC-SHA256
        byte[] secretBytes = secret.getBytes(StandardCharsets.UTF_8);
        if (secretBytes.length < 32) {
            throw new IllegalArgumentException(
                "JWT secret must be at least 32 characters (256 bits). " +
                "Current length: " + secretBytes.length + " bytes. " +
                "Generate a secure secret with: openssl rand -base64 32");
        }
        this.key = Keys.hmacShaKeyFor(secretBytes);
        this.accessTokenExpiryMs = accessTokenExpiryMs;
        this.pendingMfaTokenExpiryMs = pendingMfaTokenExpiryMs;
        this.issuer = issuer;
        this.audience = audience;
    }

    // ── Access tokens ──────────────────────────────────────────────────────

    public String generateAccessToken(String userId) {
        return Jwts.builder()
                .id(UUID.randomUUID().toString())
                .subject(userId)
                .issuer(issuer)
                .audience().add(audience).and()
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + accessTokenExpiryMs))
                .signWith(key)
                .compact();
    }

    public String getUserIdFromToken(String token) {
        return parseClaims(token).getSubject();
    }

    public String getJtiFromToken(String token) {
        return parseClaims(token).getId();
    }

    public Date getExpirationFromToken(String token) {
        return parseClaims(token).getExpiration();
    }

    public boolean validateToken(String token) {
        try {
            Claims claims = parseClaims(token);
            if (!issuer.equals(claims.getIssuer())) return false;
            if (claims.getAudience() == null || !claims.getAudience().contains(audience)) return false;
            // Reject pending MFA tokens being used as access tokens
            if (MFA_PURPOSE.equals(claims.get("purpose", String.class))) return false;
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    // ── Pending MFA tokens (short-lived, no audience claim) ────────────────

    public String generatePendingMfaToken(String userId) {
        return Jwts.builder()
                .id(UUID.randomUUID().toString())
                .subject(userId)
                .issuer(issuer)
                .claim("purpose", MFA_PURPOSE)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + pendingMfaTokenExpiryMs))
                .signWith(key)
                .compact();
    }

    /**
     * Validates the pending MFA token and returns the userId it carries.
     * Throws 401 if the token is expired, tampered, or not a pending-MFA token.
     */
    public String getUserIdFromPendingMfaToken(String token) {
        try {
            Claims claims = parseClaims(token);
            if (!issuer.equals(claims.getIssuer())) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid session token");
            }
            if (!MFA_PURPOSE.equals(claims.get("purpose", String.class))) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid session token");
            }
            return claims.getSubject();
        } catch (ExpiredJwtException e) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Verification session expired. Please sign in again.");
        } catch (JwtException e) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid session token");
        }
    }

    // ── Internal ───────────────────────────────────────────────────────────

    private Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
