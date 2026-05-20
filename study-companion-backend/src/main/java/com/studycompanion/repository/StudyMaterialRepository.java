package com.studycompanion.repository;

import com.studycompanion.model.StudyMaterial;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

public interface StudyMaterialRepository extends MongoRepository<StudyMaterial, String> {
    List<StudyMaterial> findByUserId(String userId);
}
