package com.studycompanion.service;

import com.studycompanion.model.StudyMaterial;
import com.studycompanion.model.StudyPlan;
import com.studycompanion.repository.StudyPlanRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class StudyPlanService {

    private final StudyPlanRepository planRepository;
    private final MaterialService materialService;
    private final AiService aiService;

    public StudyPlan generate(String materialId, String userId, String subject, LocalDate examDate) {
        StudyMaterial material = materialService.getById(materialId, userId);
        StudyPlan plan = aiService.generateStudyPlan(
                material.getExtractedText(), subject, examDate, userId, materialId);
        return planRepository.save(plan);
    }

    public List<StudyPlan> getByUser(String userId) {
        return planRepository.findByUserId(userId);
    }

    public StudyPlan getById(String id, String userId) {
        return planRepository.findById(id)
                .filter(p -> p.getUserId().equals(userId))
                .orElseThrow(() -> new RuntimeException("Study plan not found"));
    }
}
