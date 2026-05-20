package com.studycompanion.repository;

import com.studycompanion.model.MfaOtp;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.Optional;

public interface MfaOtpRepository extends MongoRepository<MfaOtp, String> {
    Optional<MfaOtp> findFirstByUserIdAndUsedFalseOrderByExpiresAtDesc(String userId);
    void deleteByUserId(String userId);
}
