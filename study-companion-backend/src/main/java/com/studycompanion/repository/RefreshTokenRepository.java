package com.studycompanion.repository;

import com.studycompanion.model.RefreshToken;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.Optional;

public interface RefreshTokenRepository extends MongoRepository<RefreshToken, String> {
    Optional<RefreshToken> findByTokenHash(String tokenHash);
    void deleteByUserId(String userId);
}
