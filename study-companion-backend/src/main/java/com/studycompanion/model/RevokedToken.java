package com.studycompanion.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.util.Date;

@Data
@NoArgsConstructor
@Document(collection = "revoked_tokens")
public class RevokedToken {

    @Id
    private String id;

    @Indexed(unique = true)
    private String jti;

    // MongoDB TTL index: document is auto-deleted when this date is reached
    @Indexed(expireAfterSeconds = 0)
    private Date expiresAt;

    public RevokedToken(String jti, Date expiresAt) {
        this.jti = jti;
        this.expiresAt = expiresAt;
    }
}
