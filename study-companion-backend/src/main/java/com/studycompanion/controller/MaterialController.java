package com.studycompanion.controller;

import com.studycompanion.model.StudyMaterial;
import com.studycompanion.service.MaterialService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/materials")
@RequiredArgsConstructor
public class MaterialController {

    private final MaterialService materialService;

    @PostMapping("/upload")
    public ResponseEntity<StudyMaterial> upload(
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal String userId) throws IOException {
        return ResponseEntity.ok(materialService.upload(file, userId));
    }

    @GetMapping
    public ResponseEntity<List<StudyMaterial>> list(@AuthenticationPrincipal String userId) {
        return ResponseEntity.ok(materialService.getByUser(userId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<StudyMaterial> get(
            @PathVariable String id,
            @AuthenticationPrincipal String userId) {
        return ResponseEntity.ok(materialService.getById(id, userId));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable String id,
            @AuthenticationPrincipal String userId) {
        materialService.delete(id, userId);
        return ResponseEntity.noContent().build();
    }
}
