package com.studycompanion.repository;

import com.studycompanion.model.Quiz;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface QuizRepository extends MongoRepository<Quiz, String> {
    List<Quiz> findByUserId(String userId);
    List<Quiz> findByUserIdAndMaterialId(String userId, String materialId);
}
