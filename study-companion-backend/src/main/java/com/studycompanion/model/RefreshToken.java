package com.studycompanion.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.util.Date;

@Data
@NoArgsConstructor
@Document(collection = "refresh_tokens")
public class RefreshToken {

    @Id
    private String id;

    // SHA-256 hash of the raw token — never store the raw token in the DB
    @Indexed(unique = true)
    private String tokenHash;

    private String userId;
    private boolean revoked = false;

    // MongoDB TTL index — auto-deleted after expiry
    @Indexed(expireAfterSeconds = 0)
    private Date expiresAt;
}
