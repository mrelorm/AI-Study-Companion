package com.studycompanion.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import org.bson.types.ObjectId;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;

@Data
@NoArgsConstructor
@Document(collection = "study_materials")
public class StudyMaterial {

    @Id
    private String id;

    private String userId;
    private String filename;
    private String contentType;
    private long sizeBytes;

    // GridFS file ID for the raw file
    private ObjectId gridFsFileId;

    // Extracted plain text (used as AI context)
    private String extractedText;

    private Instant uploadedAt = Instant.now();
}
