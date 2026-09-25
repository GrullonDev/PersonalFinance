import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:personal_finance/core/services/vertex_ai_service.dart';
import 'package:personal_finance/utils/app_localization.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _aiService = GetIt.instance<VertexAiService>();

  final List<_ChatMessage> _messages = [];
  // Parallel history list kept in sync with _messages for the service call
  final List<({String role, String text})> _history = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addAiMessage(
        AppLocalizations.of(context)?.aiChatWelcome ??
            '¡Hola! Soy tu asistente financiero personal. Puedo ayudarte a entender tus gastos, analizar tus finanzas y darte recomendaciones personalizadas.\n\n¿En qué te puedo ayudar hoy?',
        addToHistory: false,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addAiMessage(String text, {bool addToHistory = true}) {
    setState(() => _messages.add(_ChatMessage(isAi: true, text: text)));
    if (addToHistory) _history.add((role: 'model', text: text));
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() => _messages.add(_ChatMessage(isAi: false, text: text)));
    _history.add((role: 'user', text: text));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();
    _addUserMessage(text);

    // Pass history without the last user message we just added
    final historySnapshot = List<({String role, String text})>.from(
      _history.sublist(0, _history.length - 1),
    );

    setState(() => _isLoading = true);
    try {
      final response = await _aiService.sendChatMessage(text, historySnapshot);
      _addAiMessage(response);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)?.aiChatTitle ??
                    'Asistente Financiero',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                AppLocalizations.of(context)?.aiChatBadge ??
                    'Powered by Gemini · Pro',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (_, i) {
              if (_isLoading && i == _messages.length) {
                return const _TypingIndicator();
              }
              return _MessageBubble(message: _messages[i]);
            },
          ),
        ),
        _buildInput(context),
      ],
    ),
  );

  Widget _buildInput(BuildContext context) => SafeArea(
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isLoading,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText:
                    AppLocalizations.of(context)?.aiChatHint ??
                    'Escribe tu pregunta financiera…',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withValues(
                          alpha: _isLoading ? 0.4 : 1.0,
                        ),
                    Theme.of(context).colorScheme.secondary.withValues(
                          alpha: _isLoading ? 0.4 : 1.0,
                        ),
                  ],
                ),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final progress = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity = (0.3 + 0.7 * (1 - (progress - 0.5).abs() * 2).clamp(0.0, 1.0));
            return Container(
              margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) => Align(
    alignment: message.isAi ? Alignment.centerLeft : Alignment.centerRight,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: message.isAi
            ? Theme.of(context).colorScheme.surfaceContainerHigh
            : Theme.of(context).primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(message.isAi ? 4 : 18),
          bottomRight: Radius.circular(message.isAi ? 18 : 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.text,
        style: TextStyle(
          fontSize: 14,
          color: message.isAi
              ? Theme.of(context).colorScheme.onSurface
              : Colors.white,
          height: 1.4,
        ),
      ),
    ),
  );
}

class _ChatMessage {
  const _ChatMessage({required this.isAi, required this.text});
  final bool isAi;
  final String text;
}
