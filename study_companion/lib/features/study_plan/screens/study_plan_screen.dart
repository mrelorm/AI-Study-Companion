import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/models.dart';
import '../../../shared/theme/app_theme.dart';

class StudyPlanScreen extends StatefulWidget {
  const StudyPlanScreen({super.key});

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen> {
  final _api = ApiClient();
  final _subjectCtrl = TextEditingController();
  List<StudyMaterial> _materials = [];
  StudyMaterial? _selectedMaterial;
  DateTime? _examDate;
  bool _generating = false;
  StudyPlan? _plan;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    super.dispose();
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

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _examDate = date);
  }

  Future<void> _generate() async {
    if (_selectedMaterial == null ||
        _examDate == null ||
        _subjectCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fill in all fields first')));
      return;
    }
    setState(() => _generating = true);
    try {
      final res = await _api.post('/study-plans/generate', data: {
        'materialId': _selectedMaterial!.id,
        'subject': _subjectCtrl.text.trim(),
        'examDate': _examDate!.toIso8601String().split('T').first,
      });
      setState(() => _plan = StudyPlan.fromJson(res.data));
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
        title: const Text('Study Plan'),
      ),
      body: _plan != null
          ? _PlanView(plan: _plan!, onReset: () => setState(() => _plan = null))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.pinkGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.pink.withValues(alpha: 0.4),
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
                                'Plan your success',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'AI generates a daily study schedule before your exam.',
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
                          child: const Icon(Icons.calendar_month_rounded,
                              color: Colors.white, size: 32),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  _Label('Subject name'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _subjectCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Organic Chemistry',
                      prefixIcon:
                          Icon(Icons.book_rounded, size: 18),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _Label('Study material'),
                  const SizedBox(height: 10),
                  if (_materials.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.upload_file_rounded,
                              color: AppTheme.textSecondary, size: 18),
                          SizedBox(width: 10),
                          Text('No materials — upload one first',
                              style:
                                  TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<StudyMaterial>(
                      value: _selectedMaterial,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon:
                            Icon(Icons.folder_rounded, size: 18),
                      ),
                      items: _materials
                          .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m.filename,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (m) =>
                          setState(() => _selectedMaterial = m),
                    ),
                  const SizedBox(height: 20),

                  _Label('Exam date'),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: _examDate != null
                            ? AppTheme.primaryLight
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: _examDate != null
                            ? Border.all(color: AppTheme.primary, width: 2)
                            : Border.all(color: AppTheme.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              color: _examDate != null
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                              size: 18),
                          const SizedBox(width: 12),
                          Text(
                            _examDate == null
                                ? 'Select exam date'
                                : _examDate!
                                    .toLocal()
                                    .toString()
                                    .split(' ')
                                    .first,
                            style: TextStyle(
                              color: _examDate == null
                                  ? AppTheme.textSecondary
                                  : AppTheme.primary,
                              fontWeight: _examDate != null
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_drop_down_rounded,
                              color: _examDate != null
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Generate button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: _generating
                          ? null
                          : AppTheme.pinkGradient,
                      color: _generating ? AppTheme.primaryLight : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _generating
                          ? null
                          : [
                              BoxShadow(
                                color: AppTheme.pink.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _generating ? null : _generate,
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
                                    Text('Building your plan...',
                                        style: TextStyle(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15)),
                                  ],
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome_rounded,
                                        color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text('Generate Study Plan',
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
          letterSpacing: -0.2,
        ),
      );
}

class _PlanView extends StatelessWidget {
  final StudyPlan plan;
  final VoidCallback onReset;
  const _PlanView({required this.plan, required this.onReset});

  // Cycle through accent colors for day cards
  static const _gradients = [
    AppTheme.primaryGradient,
    AppTheme.tealGradient,
    AppTheme.amberGradient,
    AppTheme.pinkGradient,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Plan summary header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.primaryShadow,
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  color: Colors.white, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.subject,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    const SizedBox(height: 3),
                    Text('Exam: ${plan.examDate}  •  ${plan.schedule.length} days',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              TextButton(
                onPressed: onReset,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text('New Plan',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: plan.schedule.length,
            itemBuilder: (_, i) {
              final day = plan.schedule[i];
              final gradient = _gradients[i % _gradients.length];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    // Day number accent bar
                    Container(
                      width: 56,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'DAY',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    day.date,
                                    style: TextStyle(
                                      color: gradient.colors.first,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.access_time_rounded,
                                    size: 13,
                                    color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text('${day.estimatedMinutes} min',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              day.goal,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: day.topics.map((t) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: gradient.colors.first
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(t,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: gradient.colors.first)),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
