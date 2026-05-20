package com.studycompanion.controller;

import com.studycompanion.dto.QuizGenerateRequest;
import com.studycompanion.dto.QuizSubmitRequest;
import com.studycompanion.dto.QuizSubmitResponse;
import com.studycompanion.model.Quiz;
import com.studycompanion.service.QuizService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/quizzes")
@RequiredArgsConstructor
public class QuizController {

    private final QuizService quizService;

    @PostMapping("/generate")
    public ResponseEntity<Quiz> generate(
            @RequestBody QuizGenerateRequest request,
            @AuthenticationPrincipal String userId) {
        Quiz quiz = quizService.generate(
                request.getMaterialId(), userId, request.getType(),
                request.getCount(), request.getTitle());
        return ResponseEntity.ok(quiz);
    }

    @GetMapping
    public ResponseEntity<List<Quiz>> list(@AuthenticationPrincipal String userId) {
        return ResponseEntity.ok(quizService.getByUser(userId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Quiz> get(
            @PathVariable String id,
            @AuthenticationPrincipal String userId) {
        return ResponseEntity.ok(quizService.getById(id, userId));
    }

    @PostMapping("/{id}/submit")
    public ResponseEntity<QuizSubmitResponse> submit(
            @PathVariable String id,
            @RequestBody QuizSubmitRequest request,
            @AuthenticationPrincipal String userId) {
        return ResponseEntity.ok(quizService.submit(id, userId, request));
    }
}
