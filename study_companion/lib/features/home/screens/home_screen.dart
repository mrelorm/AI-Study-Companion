import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../materials/screens/materials_screen.dart';
import '../../ai_chat/screens/ai_chat_screen.dart';
import '../../study_plan/screens/study_plan_screen.dart';
import '../../quiz/screens/quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final _screens = [
    _DashboardTab(onNavigate: (i) => setState(() => _selectedIndex = i)),
    const MaterialsScreen(),
    const AiChatScreen(),
    const QuizScreen(),
    const StudyPlanScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder_rounded),
                label: 'Library'),
            NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome_rounded),
                label: 'AI Chat'),
            NavigationDestination(
                icon: Icon(Icons.quiz_outlined),
                selectedIcon: Icon(Icons.quiz_rounded),
                label: 'Quiz'),
            NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Planner'),
          ],
        ),
      ),
    );
  }
}

// ── Dashboard ──────────────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  final void Function(int) onNavigate;
  const _DashboardTab({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = user?.name.isNotEmpty == true
        ? user!.name.split(' ').first
        : 'Student';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              firstName: firstName,
              onLogout: () => context.read<AuthProvider>().logout(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  _SectionLabel('Study Tools'),
                  const SizedBox(height: 14),
                  _ModuleGrid(onNavigate: onNavigate),
                  const SizedBox(height: 32),
                  _SectionLabel('What AI does for you'),
                  const SizedBox(height: 14),
                  ..._features.map((f) => _FeatureRow(data: f)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static final _features = [
    _FeatureData(
      icon: Icons.summarize_rounded,
      color: AppTheme.blue,
      title: 'Summarise & Key Points',
      subtitle: 'Turn 100-page notes into a concise study guide.',
    ),
    _FeatureData(
      icon: Icons.style_rounded,
      color: AppTheme.teal,
      title: 'Smart Flashcards',
      subtitle: 'Auto-generated cards — perfect for active recall.',
    ),
    _FeatureData(
      icon: Icons.psychology_rounded,
      color: AppTheme.amber,
      title: 'AI Explanations',
      subtitle: 'Ask anything. Get clear, exam-focused answers.',
    ),
    _FeatureData(
      icon: Icons.emoji_events_rounded,
      color: AppTheme.pink,
      title: 'Practice & Score',
      subtitle: 'MCQ, True/False & Short Answer with instant feedback.',
    ),
  ];
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String firstName;
  final VoidCallback onLogout;
  const _Header({required this.firstName, required this.onLogout});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  // Brand chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school_rounded,
                            color: AppTheme.primary, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'AI Study Companion',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Avatar / logout
                  GestureDetector(
                    onTap: onLogout,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: AppTheme.textSecondary, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Greeting
              Text(
                '$_greeting,',
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                '$firstName 👋',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 16),

              // Motivational banner
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ready to conquer today?',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Your AI study tools are loaded and ready.',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Module grid (Brilliant course-tile style) ──────────────────────────────────

class _ModuleData {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final int navIndex;
  const _ModuleData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.navIndex,
  });
}

class _ModuleGrid extends StatelessWidget {
  final void Function(int) onNavigate;
  const _ModuleGrid({required this.onNavigate});

  static const _modules = [
    _ModuleData(
      title: 'Study Library',
      subtitle: 'Upload & organise notes',
      icon: Icons.folder_rounded,
      gradient: AppTheme.materialsGradient,
      navIndex: 1,
    ),
    _ModuleData(
      title: 'AI Tutor',
      subtitle: 'Ask anything, get answers',
      icon: Icons.auto_awesome_rounded,
      gradient: AppTheme.aiGradient,
      navIndex: 2,
    ),
    _ModuleData(
      title: 'Practice Quiz',
      subtitle: 'Test your knowledge',
      icon: Icons.quiz_rounded,
      gradient: AppTheme.quizGradient,
      navIndex: 3,
    ),
    _ModuleData(
      title: 'Exam Planner',
      subtitle: 'Build your study schedule',
      icon: Icons.calendar_month_rounded,
      gradient: AppTheme.plannerGradient,
      navIndex: 4,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 0.95,
      children: _modules
          .map((m) => _ModuleTile(
                data: m,
                onTap: () => onNavigate(m.navIndex),
              ))
          .toList(),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final _ModuleData data;
  final VoidCallback onTap;
  const _ModuleTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: data.gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: data.gradient.colors.last.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Large faded background icon
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                data.icon,
                size: 90,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Small icon chip
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(data.icon,
                        color: Colors.white, size: 22),
                  ),
                  const Spacer(),
                  Text(
                    data.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppTheme.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }
}

// ── Feature row ────────────────────────────────────────────────────────────────

class _FeatureData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _FeatureData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

class _FeatureRow extends StatelessWidget {
  final _FeatureData data;
  const _FeatureRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 3),
                Text(data.subtitle,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}
