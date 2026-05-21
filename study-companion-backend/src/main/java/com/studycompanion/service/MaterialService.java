package com.studycompanion.service;

import com.studycompanion.model.StudyMaterial;
import com.studycompanion.repository.StudyMaterialRepository;
import lombok.RequiredArgsConstructor;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.bson.types.ObjectId;
import org.springframework.data.mongodb.gridfs.GridFsTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class MaterialService {

    private final GridFsTemplate gridFsTemplate;
    private final StudyMaterialRepository materialRepository;

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of("pdf", "txt", "md");
    private static final Set<String> ALLOWED_CONTENT_TYPES = Set.of(
            "application/pdf", "text/plain", "text/markdown",
            "text/x-markdown", "application/octet-stream");
    private static final long MAX_FILE_SIZE   = 20  * 1024 * 1024; // 20 MB per file
    private static final long MAX_TOTAL_BYTES = 100 * 1024 * 1024; // 100 MB per user
    private static final int  MAX_FILES       = 20;                 // max 20 files per user

    private void validateFile(MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "No file provided");
        }
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "File exceeds 20 MB limit");
        }
        // Validate extension
        String filename = file.getOriginalFilename() != null ? file.getOriginalFilename().toLowerCase() : "";
        String ext = filename.contains(".") ? filename.substring(filename.lastIndexOf('.') + 1) : "";
        if (!ALLOWED_EXTENSIONS.contains(ext)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Only PDF, TXT, and MD files are allowed");
        }
        // Validate content type (don't trust it alone — also check magic bytes)
        String contentType = file.getContentType() != null ? file.getContentType().toLowerCase() : "";
        if (ALLOWED_CONTENT_TYPES.stream().noneMatch(contentType::startsWith)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid file type");
        }
        // For PDFs verify magic bytes (%PDF-)
        if (ext.equals("pdf")) {
            byte[] header = new byte[5];
            int read = file.getInputStream().read(header);
            if (read < 5 || header[0] != '%' || header[1] != 'P' ||
                    header[2] != 'D' || header[3] != 'F' || header[4] != '-') {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "File does not appear to be a valid PDF");
            }
        }
    }

    public StudyMaterial upload(MultipartFile file, String userId) throws IOException {
        validateFile(file);

        // Enforce per-user quota
        List<StudyMaterial> existing = materialRepository.findByUserId(userId);
        if (existing.size() >= MAX_FILES) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Upload limit reached. You can store up to " + MAX_FILES + " files.");
        }
        long totalBytes = existing.stream().mapToLong(StudyMaterial::getSizeBytes).sum();
        if (totalBytes + file.getSize() > MAX_TOTAL_BYTES) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Storage limit reached. You have used " + (totalBytes / (1024 * 1024)) +
                    " MB of your 100 MB allowance.");
        }

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
