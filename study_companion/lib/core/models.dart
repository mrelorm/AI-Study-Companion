// Shared model classes mirroring the backend DTOs

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String email;
  final String name;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.email,
    required this.name,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'] ?? '',
        refreshToken: json['refreshToken'] ?? '',
        userId: json['userId'] ?? '',
        email: json['email'] ?? '',
        name: json['name'] ?? '',
      );
}

class StudyMaterial {
  final String id;
  final String filename;
  final String contentType;
  final int sizeBytes;
  final String? extractedText;
  final DateTime uploadedAt;

  StudyMaterial({
    required this.id,
    required this.filename,
    required this.contentType,
    required this.sizeBytes,
    this.extractedText,
    required this.uploadedAt,
  });

  factory StudyMaterial.fromJson(Map<String, dynamic> json) => StudyMaterial(
        id: json['id'],
        filename: json['filename'],
        contentType: json['contentType'] ?? '',
        sizeBytes: json['sizeBytes'] ?? 0,
        extractedText: json['extractedText'],
        uploadedAt: DateTime.parse(json['uploadedAt']),
      );
}

class FlashCard {
  final String front;
  final String back;
  bool flipped;

  FlashCard({required this.front, required this.back, this.flipped = false});

  factory FlashCard.fromJson(Map<String, dynamic> json) =>
      FlashCard(front: json['front'], back: json['back']);
}

class StudyPlan {
  final String id;
  final String subject;
  final String examDate;
  final List<DayPlan> schedule;

  StudyPlan({
    required this.id,
    required this.subject,
    required this.examDate,
    required this.schedule,
  });

  factory StudyPlan.fromJson(Map<String, dynamic> json) => StudyPlan(
        id: json['id'],
        subject: json['subject'] ?? '',
        examDate: json['examDate'] ?? '',
        schedule: (json['schedule'] as List? ?? [])
            .map((d) => DayPlan.fromJson(d))
            .toList(),
      );
}

class DayPlan {
  final String date;
  final List<String> topics;
  final String goal;
  final int estimatedMinutes;

  DayPlan({
    required this.date,
    required this.topics,
    required this.goal,
    required this.estimatedMinutes,
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) => DayPlan(
        date: json['date'] ?? '',
        topics: List<String>.from(json['topics'] ?? []),
        goal: json['goal'] ?? '',
        estimatedMinutes: json['estimatedMinutes'] ?? 0,
      );
}

class Quiz {
  final String id;
  final String title;
  final List<QuizQuestion> questions;

  Quiz({required this.id, required this.title, required this.questions});

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
        id: json['id'],
        title: json['title'] ?? 'Quiz',
        questions: (json['questions'] as List? ?? [])
            .map((q) => QuizQuestion.fromJson(q))
            .toList(),
      );
}

class QuizQuestion {
  final String type;
  final String question;
  final List<String>? options;
  final String correctAnswer;
  final String explanation;

  QuizQuestion({
    required this.type,
    required this.question,
    this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        type: json['type'] ?? 'MCQ',
        question: json['question'] ?? '',
        options: json['options'] != null
            ? List<String>.from(json['options'])
            : null,
        correctAnswer: json['correctAnswer'] ?? '',
        explanation: json['explanation'] ?? '',
      );
}

class QuizResult {
  final int score;
  final int total;
  final List<QuestionResult> results;

  QuizResult({required this.score, required this.total, required this.results});

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
        score: json['score'] ?? 0,
        total: json['total'] ?? 0,
        results: (json['results'] as List? ?? [])
            .map((r) => QuestionResult.fromJson(r))
            .toList(),
      );

  double get percentage => total > 0 ? (score / total) * 100 : 0;
}

class QuestionResult {
  final int index;
  final String question;
  final String yourAnswer;
  final String correctAnswer;
  final bool correct;
  final String explanation;

  QuestionResult({
    required this.index,
    required this.question,
    required this.yourAnswer,
    required this.correctAnswer,
    required this.correct,
    required this.explanation,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> json) => QuestionResult(
        index: json['index'] ?? 0,
        question: json['question'] ?? '',
        yourAnswer: json['yourAnswer'] ?? '',
        correctAnswer: json['correctAnswer'] ?? '',
        correct: json['correct'] ?? false,
        explanation: json['explanation'] ?? '',
      );
}
