package com.studycompanion.dto;

import lombok.Data;

@Data
public class QuizGenerateRequest {
    private String materialId;
    private String type;   // MCQ, SHORT_ANSWER, TRUE_FALSE
    private int count = 10;
    private String title;
}
