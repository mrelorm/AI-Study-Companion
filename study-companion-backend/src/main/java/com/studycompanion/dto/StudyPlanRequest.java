package com.studycompanion.dto;

import lombok.Data;

import java.time.LocalDate;

@Data
public class StudyPlanRequest {
    private String materialId;
    private String subject;
    private LocalDate examDate;
}
