package com.studycompanion.service;

import com.studycompanion.model.StudyMaterial;
import com.studycompanion.repository.StudyMaterialRepository;
import lombok.RequiredArgsConstructor;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.bson.types.ObjectId;
import org.springframework.data.mongodb.gridfs.GridFsTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@Service
@RequiredArgsConstructor
public class MaterialService {

    private final GridFsTemplate gridFsTemplate;
    private final StudyMaterialRepository materialRepository;

    public StudyMaterial upload(MultipartFile file, String userId) throws IOException {
        // Store raw file in GridFS
        ObjectId fileId = gridFsTemplate.store(
                file.getInputStream(), file.getOriginalFilename(), file.getContentType());

        // Extract text from PDF (or plain text files)
        String extractedText = extractText(file);

        StudyMaterial material = new StudyMaterial();
        material.setUserId(userId);
        material.setFilename(file.getOriginalFilename());
        material.setContentType(file.getContentType());
        material.setSizeBytes(file.getSize());
        material.setGridFsFileId(fileId);
        material.setExtractedText(extractedText);

        return materialRepository.save(material);
    }

    public List<StudyMaterial> getByUser(String userId) {
        return materialRepository.findByUserId(userId);
    }

    public StudyMaterial getById(String id, String userId) {
        return materialRepository.findById(id)
                .filter(m -> m.getUserId().equals(userId))
                .orElseThrow(() -> new RuntimeException("Material not found"));
    }

    public void delete(String id, String userId) {
        StudyMaterial material = getById(id, userId);
        gridFsTemplate.delete(
                new org.springframework.data.mongodb.core.query.Query(
                        org.springframework.data.mongodb.core.query.Criteria
                                .where("_id").is(material.getGridFsFileId())));
        materialRepository.delete(material);
    }

    private String extractText(MultipartFile file) throws IOException {
        String contentType = file.getContentType();
        if (contentType != null && contentType.equals("application/pdf")) {
            try (PDDocument doc = Loader.loadPDF(file.getBytes())) {
                return new PDFTextStripper().getText(doc);
            }
        }
        // Plain text / markdown
        if (contentType != null && (contentType.startsWith("text/") ||
                contentType.equals("application/octet-stream"))) {
            return new String(file.getBytes());
        }
        return "";
    }
}
