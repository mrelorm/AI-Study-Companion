package com.studycompanion.repository;

import com.studycompanion.model.RevokedToken;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface RevokedTokenRepository extends MongoRepository<RevokedToken, String> {
    boolean existsByJti(String jti);
}
