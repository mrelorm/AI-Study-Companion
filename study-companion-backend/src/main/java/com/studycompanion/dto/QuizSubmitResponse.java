package com.studycompanion.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class QuizSubmitResponse {
    private int score;
    private int total;
    private List<Result> results;

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class Result {
        private int index;
        private String question;
        private String yourAnswer;
        private String correctAnswer;
        private boolean correct;
        private String explanation;
    }
}
