package com.studycompanion.controller;

import com.studycompanion.dto.StudyPlanRequest;
import com.studycompanion.model.StudyPlan;
import com.studycompanion.service.StudyPlanService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/study-plans")
@RequiredArgsConstructor
public class StudyPlanController {

    private final StudyPlanService studyPlanService;

    @PostMapping("/generate")
    public ResponseEntity<StudyPlan> generate(
            @RequestBody StudyPlanRequest request,
            @AuthenticationPrincipal String userId) {
        StudyPlan plan = studyPlanService.generate(
                request.getMaterialId(), userId, request.getSubject(), request.getExamDate());
        return ResponseEntity.ok(plan);
    }

    @GetMapping
    public ResponseEntity<List<StudyPlan>> list(@AuthenticationPrincipal String userId) {
        return ResponseEntity.ok(studyPlanService.getByUser(userId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<StudyPlan> get(
            @PathVariable String id,
            @AuthenticationPrincipal String userId) {
        return ResponseEntity.ok(studyPlanService.getById(id, userId));
    }
}
