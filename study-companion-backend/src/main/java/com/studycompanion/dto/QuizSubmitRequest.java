package com.studycompanion.dto;

import lombok.Data;

import java.util.Map;

@Data
public class QuizSubmitRequest {
    // key = question index (0-based), value = student's answer
    private Map<Integer, String> answers;
}
