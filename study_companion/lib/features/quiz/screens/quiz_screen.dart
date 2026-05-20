import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/models.dart';
import '../../../shared/theme/app_theme.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _api = ApiClient();
  List<StudyMaterial> _materials = [];
  StudyMaterial? _selectedMaterial;
  String _type = 'MCQ';
  int _count = 10;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    try {
      final res = await _api.get('/materials');
      setState(() {
        _materials =
            (res.data as List).map((e) => StudyMaterial.fromJson(e)).toList();
        if (_materials.isNotEmpty) _selectedMaterial = _materials.first;
      });
    } catch (_) {}
  }

  Future<void> _generateQuiz() async {
    if (_selectedMaterial == null) return;
    setState(() => _generating = true);
    try {
      final res = await _api.post('/quizzes/generate', data: {
        'materialId': _selectedMaterial!.id,
        'type': _type,
        'count': _count,
      });
      final quiz = Quiz.fromJson(res.data);
      if (mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    _TakeQuizScreen(quiz: quiz, api: _api)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: $e'),
                backgroundColor: AppTheme.error));
      }
    } finally {
      setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Quiz Generator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.amberGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.amber.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Test yourself!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Generate a quiz from your study materials.',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.quiz_rounded,
                        color: Colors.white, size: 32),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _SectionLabel('Choose material'),
            const SizedBox(height: 10),
            if (_materials.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.upload_file_rounded,
                        color: AppTheme.textSecondary, size: 20),
                    SizedBox(width: 10),
                    Text('No materials — upload one first',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              )
            else
              DropdownButtonFormField<StudyMaterial>(
                value: _selectedMaterial,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.folder_rounded, size: 18),
                ),
                items: _materials
                    .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.filename,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14))))
                    .toList(),
                onChanged: (m) => setState(() => _selectedMaterial = m),
              ),
            const SizedBox(height: 24),

            _SectionLabel('Question type'),
            const SizedBox(height: 12),
            Row(
              children: [
                _TypeChip(
                    label: 'MCQ',
                    icon: Icons.radio_button_checked_rounded,
                    selected: _type == 'MCQ',
                    onTap: () => setState(() => _type = 'MCQ')),
                const SizedBox(width: 10),
                _TypeChip(
                    label: 'True / False',
                    icon: Icons.check_circle_outline_rounded,
                    selected: _type == 'TRUE_FALSE',
                    onTap: () => setState(() => _type = 'TRUE_FALSE')),
                const SizedBox(width: 10),
                _TypeChip(
                    label: 'Short Answer',
                    icon: Icons.edit_rounded,
                    selected: _type == 'SHORT_ANSWER',
                    onTap: () => setState(() => _type = 'SHORT_ANSWER')),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionLabel('Questions'),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16),
                  ),
                ),
              ],
            ),
            Slider(
              value: _count.toDouble(),
              min: 5,
              max: 20,
              divisions: 3,
              onChanged: (v) => setState(() => _count = v.round()),
            ),
            const SizedBox(height: 32),

            // Generate button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: (_generating || _selectedMaterial == null)
                    ? null
                    : AppTheme.amberGradient,
                color: (_generating || _selectedMaterial == null)
                    ? AppTheme.primaryLight
                    : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: (_generating || _selectedMaterial == null)
                    ? null
                    : [
                        BoxShadow(
                          color: AppTheme.amber.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: (_generating || _selectedMaterial == null)
                      ? null
                      : _generateQuiz,
                  child: Center(
                    child: _generating
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppTheme.primary),
                              ),
                              SizedBox(width: 12),
                              Text('Generating your quiz...',
                                  style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                            ],
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 22),
                              SizedBox(width: 8),
                              Text('Generate Quiz',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
          letterSpacing: -0.2,
        ),
      );
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.primaryGradient : null,
          color: selected ? null : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: selected ? null : Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Take Quiz ──────────────────────────────────────────────────────────────

class _TakeQuizScreen extends StatefulWidget {
  final Quiz quiz;
  final ApiClient api;

  const _TakeQuizScreen({required this.quiz, required this.api});

  @override
  State<_TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends State<_TakeQuizScreen> {
  final Map<int, String> _answers = {};
  bool _submitting = false;
  int _currentQ = 0;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final res = await widget.api.post(
          '/quizzes/${widget.quiz.id}/submit',
          data: {'answers': _answers});
      final result = QuizResult.fromJson(res.data);
      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => _QuizResultScreen(result: result)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.quiz.questions;
    final q = questions[_currentQ];
    final isLast = _currentQ == questions.length - 1;
    final progress = (_currentQ + 1) / questions.length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(
          'Question ${_currentQ + 1} of ${questions.length}',
          style: const TextStyle(fontSize: 16),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.primaryLight,
                valueColor:
                    const AlwaysStoppedAnimation(AppTheme.primary),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      q.type.replaceAll('_', ' '),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    q.question,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1.4,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (q.options != null) ...[
                    ...q.options!.asMap().entries.map((e) => _OptionTile(
                          option: e.value,
                          index: e.key,
                          selected: _answers[_currentQ] == e.value,
                          onTap: () =>
                              setState(() => _answers[_currentQ] = e.value),
                        )),
                  ] else ...[
                    TextField(
                      decoration: const InputDecoration(
                          hintText: 'Type your answer here...'),
                      maxLines: 4,
                      onChanged: (v) => _answers[_currentQ] = v,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: AppTheme.surface,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (_currentQ > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentQ--),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: _submitting
                            ? null
                            : AppTheme.primaryGradient,
                        color: _submitting ? AppTheme.primaryLight : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow:
                            _submitting ? null : AppTheme.primaryShadow,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _submitting
                              ? null
                              : isLast
                                  ? _submit
                                  : () => setState(() => _currentQ++),
                          child: Center(
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppTheme.primary),
                                  )
                                : Text(
                                    isLast ? 'Submit Quiz' : 'Next',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String option;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  static const _labels = ['A', 'B', 'C', 'D', 'E'];

  const _OptionTile({
    required this.option,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = index < _labels.length ? _labels[index] : '${index + 1}';
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.primaryGradient : null,
          color: selected ? null : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: selected ? null : Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppTheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  color: selected ? Colors.white : AppTheme.textPrimary,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quiz Result ────────────────────────────────────────────────────────────

class _QuizResultScreen extends StatelessWidget {
  final QuizResult result;
  const _QuizResultScreen({required this.result});

  @override
  Widget build(BuildContext context) {
    final pct = result.percentage;
    final isGreat = pct >= 70;
    final isOk = pct >= 50;
    final gradient = isGreat
        ? AppTheme.tealGradient
        : isOk
            ? AppTheme.amberGradient
            : const LinearGradient(
                colors: [Color(0xFFFF5252), Color(0xFFFF1744)]);
    final emoji = isGreat ? '🎉' : isOk ? '📚' : '💪';
    final message = isGreat
        ? 'Great job!'
        : isOk
            ? 'Keep studying!'
            : 'Don\'t give up!';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Your Results'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${result.score} / ${result.total} correct',
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: result.results.length,
              itemBuilder: (_, i) {
                final r = result.results[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border(
                      left: BorderSide(
                        color: r.correct ? AppTheme.teal : AppTheme.error,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: r.correct
                                  ? AppTheme.teal.withValues(alpha: 0.12)
                                  : AppTheme.error.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              r.correct
                                  ? Icons.check_rounded
                                  : Icons.close_rounded,
                              color:
                                  r.correct ? AppTheme.teal : AppTheme.error,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              r.question,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      if (!r.correct) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.close_rounded,
                                  color: AppTheme.error, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text('Your answer: ${r.yourAnswer}',
                                    style: const TextStyle(
                                        color: AppTheme.error,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.teal.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_rounded,
                                  color: AppTheme.teal, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text('Correct: ${r.correctAnswer}',
                                    style: const TextStyle(
                                        color: AppTheme.teal, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        r.explanation,
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.5),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
