package com.studycompanion.service;

import com.studycompanion.dto.QuizSubmitRequest;
import com.studycompanion.dto.QuizSubmitResponse;
import com.studycompanion.model.Quiz;
import com.studycompanion.model.StudyMaterial;
import com.studycompanion.repository.QuizRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class QuizService {

    private final QuizRepository quizRepository;
    private final MaterialService materialService;
    private final AiService aiService;

    public Quiz generate(String materialId, String userId, String type, int count, String title) {
        StudyMaterial material = materialService.getById(materialId, userId);
        List<Quiz.Question> questions = aiService.generateQuizQuestions(
                material.getExtractedText(), type, count);

        Quiz quiz = new Quiz();
        quiz.setUserId(userId);
        quiz.setMaterialId(materialId);
        quiz.setTitle(title != null ? title : "Quiz on " + material.getFilename());
        quiz.setQuestions(questions);
        return quizRepository.save(quiz);
    }

    public List<Quiz> getByUser(String userId) {
        return quizRepository.findByUserId(userId);
    }

    public Quiz getById(String id, String userId) {
        return quizRepository.findById(id)
                .filter(q -> q.getUserId().equals(userId))
                .orElseThrow(() -> new RuntimeException("Quiz not found"));
    }

    public QuizSubmitResponse submit(String quizId, String userId, QuizSubmitRequest request) {
        Quiz quiz = getById(quizId, userId);
        Map<Integer, String> answers = request.getAnswers();
        List<QuizSubmitResponse.Result> results = new ArrayList<>();
        int score = 0;

        List<Quiz.Question> questions = quiz.getQuestions();
        for (int i = 0; i < questions.size(); i++) {
            Quiz.Question q = questions.get(i);
            String userAnswer = answers.getOrDefault(i, "");
            boolean correct = q.getCorrectAnswer().trim().equalsIgnoreCase(userAnswer.trim());
            if (correct) score++;
            results.add(new QuizSubmitResponse.Result(
                    i, q.getQuestion(), userAnswer, q.getCorrectAnswer(), correct, q.getExplanation()));
        }

        return new QuizSubmitResponse(score, questions.size(), results);
    }
}
