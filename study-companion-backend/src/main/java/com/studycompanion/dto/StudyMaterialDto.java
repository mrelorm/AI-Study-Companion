package com.studycompanion.dto;

import com.studycompanion.model.StudyMaterial;
import lombok.Data;

import java.time.Instant;

/**
 * Public-facing representation of a StudyMaterial.
 * Intentionally excludes extractedText (large, internal) and gridFsFileId (infrastructure detail).
 */
@Data
public class StudyMaterialDto {

    private String id;
    private String filename;
    private String contentType;
    private long sizeBytes;
    private Instant uploadedAt;

    public static StudyMaterialDto from(StudyMaterial m) {
        StudyMaterialDto dto = new StudyMaterialDto();
        dto.setId(m.getId());
        dto.setFilename(m.getFilename());
        dto.setContentType(m.getContentType());
        dto.setSizeBytes(m.getSizeBytes());
        dto.setUploadedAt(m.getUploadedAt());
        return dto;
    }
}
