package com.studycompanion.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.util.Date;

@Data
@NoArgsConstructor
@Document(collection = "mfa_otps")
public class MfaOtp {

    @Id
    private String id;

    // One active OTP per user at a time — old ones are replaced on resend
    @Indexed
    private String userId;

    // SHA-256 hash of the 6-digit code; raw code is never stored
    private String otpHash;

    private boolean used = false;

    private int failedAttempts = 0;

    // MongoDB TTL auto-deletes the document after expiry
    @Indexed(expireAfterSeconds = 0)
    private Date expiresAt;
}
