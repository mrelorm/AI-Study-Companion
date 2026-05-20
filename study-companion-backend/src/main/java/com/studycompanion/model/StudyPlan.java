package com.studycompanion.model;

import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDate;
import java.time.Instant;
import java.util.List;

@Data
@NoArgsConstructor
@Document(collection = "study_plans")
public class StudyPlan {

    @Id
    private String id;

    private String userId;
    private String materialId;
    private String subject;
    private LocalDate examDate;
    private List<DayPlan> schedule;
    private Instant createdAt = Instant.now();

    @Data
    @NoArgsConstructor
    public static class DayPlan {
        private LocalDate date;
        private List<String> topics;
        private String goal;
        private int estimatedMinutes;
    }
}
