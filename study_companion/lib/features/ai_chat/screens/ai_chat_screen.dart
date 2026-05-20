import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/api_client.dart';
import '../../../core/models.dart';
import '../../../shared/theme/app_theme.dart';

enum AiAction { explain, summarize, keyPoints, revisionNotes }

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => AiChatScreenState();
}

// Public so HomeScreen can call refreshMaterials() on tab switch
// ignore: library_private_types_in_public_api

class AiChatScreenState extends State<AiChatScreen> with WidgetsBindingObserver {
  final _api = ApiClient();
  final _questionCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<StudyMaterial> _materials = [];
  StudyMaterial? _selectedMaterial;
  AiAction _selectedAction = AiAction.explain;
  final List<_ChatMessage> _messages = [];
  bool _thinking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMaterials();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadMaterials();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _questionCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Called by HomeScreen when the AI Chat tab is tapped
  void refreshMaterials() => _loadMaterials();

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

  Future<void> _send() async {
    if (_selectedMaterial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a material first')));
      return;
    }
    final question = _questionCtrl.text.trim();
    if (_selectedAction == AiAction.explain && question.isEmpty) return;

    _questionCtrl.clear();
    setState(() {
      _messages.add(_ChatMessage(
          text: question.isNotEmpty ? question : _actionLabel(_selectedAction),
          isUser: true));
      _thinking = true;
    });
    _scrollToBottom();

    try {
      final body = {
        'materialId': _selectedMaterial!.id,
        'question': question,
        'instructions': question,
      };

      final endpoint = switch (_selectedAction) {
        AiAction.explain => '/ai/explain',
        AiAction.summarize => '/ai/summarize',
        AiAction.keyPoints => '/ai/key-points',
        AiAction.revisionNotes => '/ai/revision-notes',
      };

      final res = await _api.post(endpoint, data: body);
      setState(() {
        _messages.add(_ChatMessage(
            text: res.data['result'] ?? 'No response', isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.add(
            _ChatMessage(text: 'Error: $e', isUser: false, isError: true));
      });
    } finally {
      setState(() => _thinking = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  String _actionLabel(AiAction a) => switch (a) {
        AiAction.explain => 'Explain this topic',
        AiAction.summarize => 'Summarise this material',
        AiAction.keyPoints => 'Extract key points',
        AiAction.revisionNotes => 'Generate revision notes',
      };

  IconData _actionIcon(AiAction a) => switch (a) {
        AiAction.explain => Icons.lightbulb_outline_rounded,
        AiAction.summarize => Icons.summarize_rounded,
        AiAction.keyPoints => Icons.format_list_bulleted_rounded,
        AiAction.revisionNotes => Icons.edit_note_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('AI Assistant'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: AppTheme.background,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _materials.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHigh,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: AppTheme.textSecondary),
                        SizedBox(width: 8),
                        Text('Upload a material to start chatting',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  )
                : DropdownButtonFormField<StudyMaterial>(
                    value: _selectedMaterial,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(Icons.folder_rounded, size: 18),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: _materials
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m.filename,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (m) => setState(() => _selectedMaterial = m),
                  ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Action chips row
          Container(
            color: AppTheme.background,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AiAction.values.map((action) {
                  final selected = _selectedAction == action;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedAction = action),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient:
                              selected ? AppTheme.primaryGradient : null,
                          color: selected ? null : AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : AppTheme.cardShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _actionIcon(action),
                              size: 15,
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _actionLabel(action),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Messages
          Expanded(
            child: _messages.isEmpty
                ? _EmptyChat(action: _selectedAction)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _messages.length + (_thinking ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _messages.length) {
                        return const _ThinkingBubble();
                      }
                      return _MessageBubble(message: _messages[i]);
                    },
                  ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: const Border(
                  top: BorderSide(color: AppTheme.border, width: 1)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: TextField(
                        controller: _questionCtrl,
                        decoration: InputDecoration(
                          hintText: _selectedAction == AiAction.explain
                              ? 'Ask anything about the material...'
                              : 'Add instructions (optional)...',
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          fillColor: Colors.transparent,
                        ),
                        onSubmitted: (_) => _send(),
                        maxLines: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient:
                          _thinking ? null : AppTheme.primaryGradient,
                      color: _thinking ? AppTheme.primaryLight : null,
                      shape: BoxShape.circle,
                      boxShadow:
                          _thinking ? null : AppTheme.primaryShadow,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(23),
                        onTap: _thinking ? null : _send,
                        child: Center(
                          child: _thinking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primary),
                                )
                              : const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 20),
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

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  _ChatMessage(
      {required this.text, required this.isUser, this.isError = false});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          gradient: message.isUser ? AppTheme.primaryGradient : null,
          color: message.isUser
              ? null
              : message.isError
                  ? AppTheme.error.withValues(alpha: 0.08)
                  : AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.isUser ? 18 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 18),
          ),
          boxShadow: message.isUser
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : AppTheme.cardShadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: message.isUser
            ? Text(message.text,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, height: 1.4))
            : MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      height: 1.6),
                  code: const TextStyle(
                      backgroundColor: AppTheme.surfaceHigh, fontSize: 13),
                  h1: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                  h2: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                  strong: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                ),
              ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppTheme.primary),
            ),
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.6)),
            ),
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            const SizedBox(width: 10),
            const Text('AI is thinking...',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final AiAction action;
  const _EmptyChat({required this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.primaryShadow,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 42, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ask the AI anything',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),
            const Text(
              'Select a material, choose an action,\nand type your question to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
