package com.studycompanion.dto;

import lombok.Data;

@Data
public class AiRequest {
    private String materialId;
    private String question;       // for /explain
    private String instructions;   // for /summarize
}
