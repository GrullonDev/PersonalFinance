import 'package:flutter/material.dart';
import 'package:personal_finance/utils/app_localization.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<_ChatMessage> _messages(BuildContext context) => [
    _ChatMessage(
      isAi: true,
      text:
          AppLocalizations.of(context)?.aiChatWelcome ??
          '¡Hola! Soy tu asistente financiero personal. Puedo ayudarte a entender tus gastos, analizar tus finanzas y darte recomendaciones personalizadas.\n\n¿En qué te puedo ayudar hoy?',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F7F9),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF6F7F9),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
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
                    'Powered by IA · Pro',
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFF6366F1).withValues(alpha: 0.8),
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
            itemCount: _messages(context).length,
            itemBuilder:
                (_, i) => _MessageBubble(message: _messages(context)[i]),
          ),
        ),
        _buildComingSoonBanner(context),
        _buildInput(context),
      ],
    ),
  );

  Widget _buildComingSoonBanner(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF6366F1).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.rocket_launch_rounded,
          size: 15,
          color: Color(0xFF6366F1),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.of(context)?.aiChatComingSoon ??
                'El chat con IA estará disponible muy pronto. ¡Mantente al tanto!',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF6366F1).withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildInput(BuildContext context) => SafeArea(
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
              enabled: false,
              decoration: InputDecoration(
                hintText:
                    AppLocalizations.of(context)?.aiChatHint ??
                    'Escribe tu pregunta financiera…',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF6F7F9),
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.4),
                  const Color(0xFFEC4899).withValues(alpha: 0.4),
                ],
              ),
            ),
            child: const Icon(
              Icons.send_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
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
        color: message.isAi ? Colors.white : const Color(0xFF6366F1),
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
          color: message.isAi ? Colors.black87 : Colors.white,
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
