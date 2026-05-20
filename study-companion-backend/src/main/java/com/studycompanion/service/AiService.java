package com.studycompanion.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.studycompanion.dto.FlashcardDto;
import com.studycompanion.model.Quiz;
import com.studycompanion.model.StudyPlan;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AiService {

    private final GeminiService gemini;
    private final ObjectMapper objectMapper;

    public String explainTopic(String materialText, String question) {
        String prompt = """
                You are an expert tutor. Using the following study material, answer the student's question
                in a clear, simple way that's easy to understand. Use analogies if helpful.

                STUDY MATERIAL:
                %s

                STUDENT'S QUESTION: %s

                Provide a thorough but accessible explanation.
                """.formatted(truncate(materialText, 8000), question);
        return gemini.generate(prompt);
    }

    public String summarize(String materialText, String instructions) {
        String prompt = """
                You are a study assistant. Summarize the following material.
                Instructions: %s

                MATERIAL:
                %s

                Provide a clear, structured summary.
                """.formatted(instructions, truncate(materialText, 8000));
        return gemini.generate(prompt);
    }

    public String extractKeyPoints(String materialText) {
        String prompt = """
                Extract the most important key points from the following study material.
                Format the output as a numbered list of concise, exam-ready bullet points.

                MATERIAL:
                %s
                """.formatted(truncate(materialText, 8000));
        return gemini.generate(prompt);
    }

    public String generateRevisionNotes(String materialText) {
        String prompt = """
                Convert the following study material into concise, exam-ready revision notes.
                Use clear headings, bullet points, and highlight key terms.
                Structure it so a student can quickly review before an exam.

                MATERIAL:
                %s
                """.formatted(truncate(materialText, 8000));
        return gemini.generate(prompt);
    }

    public List<FlashcardDto> generateFlashcards(String materialText) {
        String prompt = """
                Create 10 flashcards from the following study material.
                Each flashcard should have a FRONT (question or term) and BACK (answer or definition).

                Return ONLY a JSON array like this:
                [{"front": "question here", "back": "answer here"}, ...]

                MATERIAL:
                %s
                """.formatted(truncate(materialText, 6000));

        String jsonText = gemini.generate(prompt);
        // Strip markdown code fences if present
        jsonText = jsonText.replaceAll("```json\\s*", "").replaceAll("```\\s*", "").trim();

        try {
            FlashcardDto[] cards = objectMapper.readValue(jsonText, FlashcardDto[].class);
            return List.of(cards);
        } catch (Exception e) {
            return List.of(new FlashcardDto("Error", "Could not parse flashcards: " + e.getMessage()));
        }
    }

    public StudyPlan generateStudyPlan(String materialText, String subject,
                                       LocalDate examDate, String userId, String materialId) {
        long daysUntilExam = LocalDate.now().until(examDate).getDays();
        if (daysUntilExam < 1) daysUntilExam = 1;

        String prompt = """
                Create a structured daily study plan for the following material.
                Subject: %s
                Exam date: %s (%d days away)

                Return ONLY a JSON array of day plans:
                [
                  {
                    "date": "YYYY-MM-DD",
                    "topics": ["topic 1", "topic 2"],
                    "goal": "What the student should achieve today",
                    "estimatedMinutes": 60
                  }
                ]

                Create a plan for each day between today and the exam.
                MATERIAL:
                %s
                """.formatted(subject, examDate, daysUntilExam, truncate(materialText, 6000));

        String jsonText = gemini.generate(prompt);
        jsonText = jsonText.replaceAll("```json\\s*", "").replaceAll("```\\s*", "").trim();

        StudyPlan plan = new StudyPlan();
        plan.setUserId(userId);
        plan.setMaterialId(materialId);
        plan.setSubject(subject);
        plan.setExamDate(examDate);

        try {
            StudyPlan.DayPlan[] days = objectMapper.readValue(jsonText, StudyPlan.DayPlan[].class);
            plan.setSchedule(List.of(days));
        } catch (Exception e) {
            plan.setSchedule(new ArrayList<>());
        }
        return plan;
    }

    public List<Quiz.Question> generateQuizQuestions(String materialText, String type, int count) {
        String prompt = """
                Generate %d %s quiz questions from the following study material.

                Return ONLY a JSON array:
                [
                  {
                    "type": "%s",
                    "question": "question text",
                    "options": ["A. ...", "B. ...", "C. ...", "D. ..."],  // null for SHORT_ANSWER
                    "correctAnswer": "A. ...",
                    "explanation": "Brief explanation of the correct answer"
                  }
                ]

                For TRUE_FALSE: options should be ["True", "False"].
                For SHORT_ANSWER: omit options field.

                MATERIAL:
                %s
                """.formatted(count, type, type, truncate(materialText, 6000));

        String jsonText = gemini.generate(prompt);
        jsonText = jsonText.replaceAll("```json\\s*", "").replaceAll("```\\s*", "").trim();

        try {
            Quiz.Question[] questions = objectMapper.readValue(jsonText, Quiz.Question[].class);
            return List.of(questions);
        } catch (Exception e) {
            return List.of();
        }
    }

    private String truncate(String text, int maxChars) {
        if (text == null) return "";
        return text.length() > maxChars ? text.substring(0, maxChars) + "..." : text;
    }
}
