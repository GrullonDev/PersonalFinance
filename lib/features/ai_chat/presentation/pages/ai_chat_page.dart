import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_finance/core/services/vertex_ai_service.dart';
import 'package:personal_finance/features/ai_chat/domain/ai_chat_quota.dart';
import 'package:personal_finance/features/ai_chat/presentation/widgets/ai_message_text.dart';
import 'package:personal_finance/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:personal_finance/features/subscription/presentation/pages/paywall_page.dart';
import 'package:personal_finance/utils/app_localization.dart';

/// Asistente financiero con IA.
///
/// Con Pro el chat es ilimitado. Sin Pro el usuario puede hacer
/// [AiChatQuota.dailyLimit] preguntas al día y ve qué gana al contratar.
/// Puede recibir como argumento de ruta un resumen de sus finanzas del mes
/// (ver `FinancialContextBuilder`) para que las respuestas usen sus datos.
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _aiService = GetIt.instance<VertexAiService>();
  final _subscriptionBloc = GetIt.instance<SubscriptionBloc>();
  late final AiChatQuota _quota = AiChatQuota(
    GetIt.instance<SharedPreferences>(),
  );

  static const List<String> _suggestions = <String>[
    '¿En qué estoy gastando más este mes?',
    '¿Cómo puedo ahorrar más este mes?',
    'Ayúdame a armar un presupuesto',
    '¿Cómo pago mis deudas más rápido?',
  ];

  final List<_ChatMessage> _messages = [];
  // Historial paralelo a _messages para enviarlo al servicio.
  final List<({String role, String text})> _history = [];
  bool _isLoading = false;
  String? _financialContext;
  bool _contextRead = false;

  bool get _isPremium => _subscriptionBloc.state.isPremium;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_contextRead) return;
    _contextRead = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) _financialContext = args;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;
    if (!_isPremium && !_quota.hasRemaining) {
      await PaywallPage.show(context);
      return;
    }

    _controller.clear();
    final historySnapshot = List<({String role, String text})>.from(_history);
    setState(() {
      _messages.add(_ChatMessage(isAi: false, text: text));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final reply = await _aiService.chat(
        text,
        historySnapshot,
        financialContext: _financialContext,
      );
      if (!mounted) return;
      setState(
        () => _messages.add(
          _ChatMessage(isAi: true, text: reply.text, isError: reply.isError),
        ),
      );
      // Los errores no cuentan como pregunta ni entran al historial.
      if (!reply.isError) {
        _history
          ..add((role: 'user', text: text))
          ..add((role: 'model', text: reply.text));
        if (!_isPremium) await _quota.consume();
      }
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openPaywall() async {
    await PaywallPage.show(context);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SubscriptionBloc, SubscriptionState>(
        bloc: _subscriptionBloc,
        builder:
            (context, _) => Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              appBar: _buildAppBar(context),
              body: Column(
                children: [
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      children: [
                        _WelcomeCard(
                          hasData: _financialContext != null,
                          suggestions:
                              _messages.isEmpty ? _suggestions : const [],
                          onSuggestion: _send,
                        ),
                        for (final m in _messages) _MessageBubble(message: m),
                        if (_isLoading) const _TypingIndicator(),
                        if (!_isPremium &&
                            !_isLoading &&
                            _messages.any((m) => m.isAi))
                          _ProUpsellCard(onTap: _openPaywall),
                      ],
                    ),
                  ),
                  _buildInput(context),
                ],
              ),
            ),
      );

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      title: Row(
        children: [
          const _AiAvatar(size: 36),
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
                _isPremium
                    ? 'Pro · Preguntas ilimitadas'
                    : 'Gratis · ${_quota.remainingToday} de ${_quota.dailyLimit} preguntas hoy',
                style: TextStyle(
                  fontSize: 11,
                  color: primary.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final secondary = Theme.of(context).colorScheme.secondary;

    if (!_isPremium && !_quota.hasRemaining && !_isLoading) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Usaste tus ${_quota.dailyLimit} preguntas gratis de hoy.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openPaywall,
                  icon: const Icon(Icons.workspace_premium_rounded),
                  label: const Text('Seguir conversando con Pro'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
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
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText:
                      AppLocalizations.of(context)?.aiChatHint ??
                      'Escribe tu pregunta financiera…',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
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
              onTap: _isLoading ? null : _send,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      primary.withValues(alpha: _isLoading ? 0.4 : 1.0),
                      secondary.withValues(alpha: _isLoading ? 0.4 : 1.0),
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
}

class _AiAvatar extends StatelessWidget {
  const _AiAvatar({this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [
          Theme.of(context).primaryColor,
          Theme.of(context).colorScheme.secondary,
        ],
      ),
    ),
    child: Icon(Icons.auto_awesome, color: Colors.white, size: size * 0.5),
  );
}

/// Saludo inicial con preguntas sugeridas para empezar con un toque.
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.hasData,
    required this.suggestions,
    required this.onSuggestion,
  });

  final bool hasData;
  final List<String> suggestions;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.12),
            scheme.secondary.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _AiAvatar(size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¡Hola! Soy tu asesor financiero 👋',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasData
                ? 'Ya revisé tus movimientos de este mes. Pregúntame en qué '
                    'gastas más, cómo ahorrar o cómo organizar tu presupuesto.'
                : 'Te ayudo a entender tus gastos, ahorrar y organizar tu '
                    'presupuesto. Registra movimientos para darte consejos '
                    'con tus propios números.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: scheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in suggestions)
                  ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 12.5)),
                    avatar: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: primary,
                    ),
                    onPressed: () => onSuggestion(s),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Invitación a Pro después de cada respuesta para quien usa el plan gratis.
class _ProUpsellCard extends StatelessWidget {
  const _ProUpsellCard({required this.onTap});
  final VoidCallback onTap;

  static const List<String> _benefits = <String>[
    'Preguntas ilimitadas al asesor',
    'Reporte mensual con IA de tus gastos',
    'Alertas antes de pasarte del presupuesto',
    'Presupuestos y metas sin límite',
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, Color.lerp(primary, const Color(0xFF1A237E), 0.4)!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '¿Quieres un control más completo de tu dinero?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final b in _benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Conocer el plan Pro',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _AiAvatar(),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder:
                (_, __) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i / 3;
                    final progress = ((_controller.value - delay) % 1.0).clamp(
                      0.0,
                      1.0,
                    );
                    final opacity =
                        0.3 +
                        0.7 * (1 - (progress - 0.5).abs() * 2).clamp(0.0, 1.0);
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
      ],
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _ChatMessage message;

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Respuesta copiada')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = Theme.of(context).primaryColor;
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            message.isError
                ? scheme.errorContainer
                : message.isAi
                ? scheme.surfaceContainerHigh
                : primary,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(message.isAi ? 4 : 18),
          bottomRight: Radius.circular(message.isAi ? 18 : 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child:
          message.isAi
              ? AiMessageText(
                text: message.text,
                color:
                    message.isError
                        ? scheme.onErrorContainer
                        : scheme.onSurface,
                accent: primary,
              )
              : Text(
                message.text,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
    );

    if (!message.isAi) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(alignment: Alignment.centerRight, child: bubble),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _AiAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _copy(context),
              child: bubble,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.isAi,
    required this.text,
    this.isError = false,
  });
  final bool isAi;
  final String text;
  final bool isError;
}
