package com.studycompanion.exception;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /** Spring Security / auth layer — preserves the intended HTTP status */
    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, Object>> handleResponseStatus(ResponseStatusException ex) {
        log.warn("ResponseStatusException [{}]: {}", ex.getStatusCode(), ex.getReason());
        return ResponseEntity.status(ex.getStatusCode()).body(Map.of(
                "error", ex.getReason() != null ? ex.getReason() : ex.getMessage(),
                "timestamp", Instant.now()
        ));
    }

    /** Bean validation failures (@Valid) */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException ex) {
        String msg = ex.getBindingResult().getFieldErrors().stream()
                .map(fe -> fe.getField() + ": " + fe.getDefaultMessage())
                .findFirst().orElse("Validation failed");
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                "error", msg,
                "timestamp", Instant.now()
        ));
    }

    /** Everything else — 500 for unexpected errors, 400 for known business errors */
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Map<String, Object>> handleRuntime(RuntimeException ex) {
        log.error("RuntimeException: {}", ex.getMessage(), ex);
        // Known business errors (material not found, AI busy, etc.) → 400
        // Unknown errors → 500
        boolean isBusinessError = ex.getMessage() != null &&
                !ex.getMessage().toLowerCase().contains("unexpected") &&
                !(ex.getCause() instanceof Error);
        HttpStatus status = isBusinessError ? HttpStatus.BAD_REQUEST : HttpStatus.INTERNAL_SERVER_ERROR;
        String message = isBusinessError
                ? ex.getMessage()
                : "An unexpected error occurred. Please try again.";
        return ResponseEntity.status(status).body(Map.of(
                "error", message,
                "timestamp", Instant.now()
        ));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleGeneric(Exception ex) {
        log.error("Unhandled exception: {}", ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "error", "Internal server error",
                "timestamp", Instant.now()
        ));
    }
}
