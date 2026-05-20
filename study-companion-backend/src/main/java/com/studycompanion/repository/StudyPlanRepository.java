package com.studycompanion.repository;

import com.studycompanion.model.StudyPlan;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface StudyPlanRepository extends MongoRepository<StudyPlan, String> {
    List<StudyPlan> findByUserId(String userId);
}
