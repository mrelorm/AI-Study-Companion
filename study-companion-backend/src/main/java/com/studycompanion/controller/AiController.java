package com.studycompanion.controller;

import com.studycompanion.dto.AiRequest;
import com.studycompanion.dto.FlashcardDto;
import com.studycompanion.model.StudyMaterial;
import com.studycompanion.service.AiService;
import com.studycompanion.service.MaterialService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class AiController {

    private final AiService aiService;
    private final MaterialService materialService;

    @PostMapping("/explain")
    public ResponseEntity<Map<String, String>> explain(
            @RequestBody AiRequest request,
            @AuthenticationPrincipal String userId) {
        StudyMaterial material = materialService.getById(request.getMaterialId(), userId);
        String result = aiService.explainTopic(material.getExtractedText(), request.getQuestion());
        return ResponseEntity.ok(Map.of("result", result));
    }

    @PostMapping("/summarize")
    public ResponseEntity<Map<String, String>> summarize(
            @RequestBody AiRequest request,
            @AuthenticationPrincipal String userId) {
        StudyMaterial material = materialService.getById(request.getMaterialId(), userId);
        String instructions = request.getInstructions() != null ? request.getInstructions() : "Provide a concise summary";
        String result = aiService.summarize(material.getExtractedText(), instructions);
        return ResponseEntity.ok(Map.of("result", result));
    }

    @PostMapping("/key-points")
    public ResponseEntity<Map<String, String>> keyPoints(
            @RequestBody AiRequest request,
            @AuthenticationPrincipal String userId) {
        StudyMaterial material = materialService.getById(request.getMaterialId(), userId);
        String result = aiService.extractKeyPoints(material.getExtractedText());
        return ResponseEntity.ok(Map.of("result", result));
    }

    @PostMapping("/revision-notes")
    public ResponseEntity<Map<String, String>> revisionNotes(
            @RequestBody AiRequest request,
            @AuthenticationPrincipal String userId) {
        StudyMaterial material = materialService.getById(request.getMaterialId(), userId);
        String result = aiService.generateRevisionNotes(material.getExtractedText());
        return ResponseEntity.ok(Map.of("result", result));
    }

    @PostMapping("/flashcards")
    public ResponseEntity<List<FlashcardDto>> flashcards(
            @RequestBody AiRequest request,
            @AuthenticationPrincipal String userId) {
        StudyMaterial material = materialService.getById(request.getMaterialId(), userId);
        List<FlashcardDto> cards = aiService.generateFlashcards(material.getExtractedText());
        return ResponseEntity.ok(cards);
    }
}
