package com.studycompanion.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.List;

@Data
@NoArgsConstructor
@Document(collection = "quizzes")
public class Quiz {

    @Id
    private String id;

    private String userId;
    private String materialId;
    private String title;
    private List<Question> questions;
    private Instant createdAt = Instant.now();

    @Data
    @NoArgsConstructor
    public static class Question {
        private String type;        // MCQ, SHORT_ANSWER, TRUE_FALSE
        private String question;
        private List<String> options; // null for SHORT_ANSWER
        private String correctAnswer;
        private String explanation;
    }
}
