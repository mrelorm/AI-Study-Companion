import 'package:flutter/material.dart';
import '../../../core/api_client.dart';
import '../../../core/models.dart';
import '../../../shared/theme/app_theme.dart';

class FlashcardsScreen extends StatefulWidget {
  final StudyMaterial material;
  const FlashcardsScreen({super.key, required this.material});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final _api = ApiClient();
  List<FlashCard> _cards = [];
  int _currentIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final res = await _api.post('/ai/flashcards',
          data: {'materialId': widget.material.id});
      setState(() {
        _cards = (res.data as List).map((e) => FlashCard.fromJson(e)).toList();
        _currentIndex = 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Flashcards'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 18),
            ),
            onPressed: _generate,
            tooltip: 'Regenerate',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.primaryShadow,
                    ),
                    child: const Icon(Icons.style_rounded,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 20),
                  const Text('Generating flashcards...',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  const SizedBox(
                    width: 160,
                    child: LinearProgressIndicator(
                      borderRadius: BorderRadius.all(Radius.circular(3)),
                    ),
                  ),
                ],
              ),
            )
          : _cards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.style_outlined,
                          size: 64, color: AppTheme.textSecondary),
                      const SizedBox(height: 16),
                      const Text('No flashcards generated',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                          onPressed: _generate,
                          child: const Text('Try again')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Progress strip
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: (_currentIndex + 1) / _cards.length,
                                minHeight: 6,
                                backgroundColor: AppTheme.primaryLight,
                                valueColor: const AlwaysStoppedAnimation(
                                    AppTheme.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${_currentIndex + 1} / ${_cards.length}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        itemCount: _cards.length,
                        onPageChanged: (i) =>
                            setState(() => _currentIndex = i),
                        itemBuilder: (_, i) =>
                            _FlashCardWidget(card: _cards[i]),
                      ),
                    ),
                    // Swipe hint
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.swipe_rounded,
                              size: 16,
                              color: AppTheme.textSecondary
                                  .withValues(alpha: 0.5)),
                          const SizedBox(width: 6),
                          Text('Swipe to go to the next card',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary
                                      .withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _FlashCardWidget extends StatefulWidget {
  final FlashCard card;
  const _FlashCardWidget({required this.card});

  @override
  State<_FlashCardWidget> createState() => _FlashCardWidgetState();
}

class _FlashCardWidgetState extends State<_FlashCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _anim = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_FlashCardWidget old) {
    super.didUpdateWidget(old);
    // Reset flip state when card changes (page swipe)
    if (old.card != widget.card) {
      _ctrl.reset();
      _showBack = false;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_showBack) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, child) {
            final angle = _anim.value * 3.14159;
            final isBack = angle > 1.5708;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: isBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(3.14159),
                      child: _CardFace(
                        text: widget.card.back,
                        label: 'ANSWER',
                        gradient: AppTheme.tealGradient,
                      ),
                    )
                  : _CardFace(
                      text: widget.card.front,
                      label: 'QUESTION',
                      gradient: AppTheme.primaryGradient,
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String text;
  final String label;
  final LinearGradient gradient;

  const _CardFace({
    required this.text,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gradient header strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    height: 1.45,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),
          // Tap hint
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_rounded,
                    size: 14,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(width: 5),
                Text(
                  'Tap to flip',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
