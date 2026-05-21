package com.studycompanion.controller;

import com.studycompanion.dto.StudyMaterialDto;
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
    public ResponseEntity<StudyMaterialDto> upload(
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal String userId) throws IOException {
        return ResponseEntity.ok(StudyMaterialDto.from(materialService.upload(file, userId)));
    }

    @GetMapping
    public ResponseEntity<List<StudyMaterialDto>> list(@AuthenticationPrincipal String userId) {
        return ResponseEntity.ok(
                materialService.getByUser(userId).stream().map(StudyMaterialDto::from).toList());
    }

    @GetMapping("/{id}")
    public ResponseEntity<StudyMaterialDto> get(
            @PathVariable String id,
            @AuthenticationPrincipal String userId) {
        return ResponseEntity.ok(StudyMaterialDto.from(materialService.getById(id, userId)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable String id,
            @AuthenticationPrincipal String userId) {
        materialService.delete(id, userId);
        return ResponseEntity.noContent().build();
    }
}
