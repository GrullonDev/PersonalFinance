import 'dart:math';

import 'package:flutter/material.dart';
import 'package:personal_finance/core/security/security_preferences.dart';
import 'package:personal_finance/core/presentation/widgets/premium_background.dart';
import 'package:personal_finance/utils/app_localization.dart';
import 'package:personal_finance/utils/routes/route_path.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  static const List<_OnboardStep> _steps = <_OnboardStep>[
    _OnboardStep(
      titleKey: 'step1Title',
      descriptionKey: 'step1Desc',
      badgeKey: 'step1Badge',
      accentColor: Color(0xFF90CAF9),
      illustration: _Step1Illustration(),
    ),
    _OnboardStep(
      titleKey: 'step2Title',
      descriptionKey: 'step2Desc',
      badgeKey: 'step2Badge',
      accentColor: Color(0xFF80DEEA),
      illustration: _Step2Illustration(),
    ),
    _OnboardStep(
      titleKey: 'step3Title',
      descriptionKey: 'step3Desc',
      badgeKey: 'step3Badge',
      accentColor: Color(0xFFFFCC80),
      illustration: _Step3Illustration(),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextPage() => _controller.nextPage(
    duration: const Duration(milliseconds: 400),
    curve: Curves.easeInOutCubic,
  );

  void _prevPage() => _controller.previousPage(
    duration: const Duration(milliseconds: 400),
    curve: Curves.easeInOutCubic,
  );

  Future<void> _complete() async {
    await SecurityPreferences.setOnboardingComplete();
    if (mounted) {
      Navigator.pushReplacementNamed(context, RoutePath.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context)!;
    final _OnboardStep step = _steps[_index];
    final bool isLast = _index == _steps.length - 1;

    return PremiumBackground(
      child: Column(
        children: <Widget>[
          // ── Top bar ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: <Widget>[
                Text(
                  '${(_index + 1).toString().padLeft(2, '0')} / '
                  '${_steps.length.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                if (!isLast)
                  TextButton(
                    onPressed: _complete,
                    child: Text(
                      loc.translate('skip'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Illustration area ───────────────────────────────────
          Expanded(
            flex: 55,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (int i) => setState(() => _index = i),
              itemCount: _steps.length,
              itemBuilder: (BuildContext _, int i) => _steps[i].illustration,
            ),
          ),

          // ── Text content ────────────────────────────────────────
          Expanded(
            flex: 45,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Badge label
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: step.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: step.accentColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      loc.translate(step.badgeKey),
                      style: TextStyle(
                        color: step.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    loc.translate(step.titleKey),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    loc.translate(step.descriptionKey),
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.6,
                    ),
                  ),

                  const Spacer(),

                  // Navigation row
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      children: <Widget>[
                        // Animated dot indicators
                        ...List<Widget>.generate(
                          _steps.length,
                          (int i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 6),
                            height: 8,
                            width: _index == i ? 28 : 8,
                            decoration: BoxDecoration(
                              color:
                                  _index == i
                                      ? _steps[i].accentColor
                                      : Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Back button
                        if (_index > 0) ...<Widget>[
                          _NavIconButton(
                            icon: Icons.arrow_back_rounded,
                            onPressed: _prevPage,
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Primary CTA
                        FilledButton(
                          onPressed: isLast ? _complete : _nextPage,
                          style: FilledButton.styleFrom(
                            backgroundColor: step.accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                isLast ? loc.getStarted : loc.next,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                isLast
                                    ? Icons.rocket_launch_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 17,
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
        ],
      ),
    );
  }
}

// ── Step 1: floating transaction cards ──────────────────────────────────────

class _Step1Illustration extends StatelessWidget {
  const _Step1Illustration();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // Radial glow + wallet icon
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                const Color(0xFF90CAF9).withValues(alpha: 0.35),
                Colors.transparent,
              ],
            ),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            size: 64,
            color: Color(0xFF90CAF9),
          ),
        ),

        const Positioned(
          top: 8,
          left: 0,
          child: _FloatingTx(
            icon: Icons.work_rounded,
            label: 'Salario',
            amount: '+Q 3,500',
            positive: true,
          ),
        ),
        const Positioned(
          bottom: 70,
          right: 0,
          child: _FloatingTx(
            icon: Icons.shopping_cart_rounded,
            label: 'Supermercado',
            amount: '-Q 320',
            positive: false,
          ),
        ),
        const Positioned(
          bottom: 10,
          left: 16,
          child: _FloatingTx(
            icon: Icons.directions_car_rounded,
            label: 'Transporte',
            amount: '-Q 45',
            positive: false,
          ),
        ),
      ],
    ),
  );
}

class _FloatingTx extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final bool positive;

  const _FloatingTx({
    required this.icon,
    required this.label,
    required this.amount,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF90CAF9).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: const Color(0xFF90CAF9)),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                color:
                    positive
                        ? const Color(0xFF81C784)
                        : const Color(0xFFEF9A9A),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ── Step 2: circular progress ring + bar chart ──────────────────────────────

class _Step2Illustration extends StatelessWidget {
  const _Step2Illustration();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // Arc ring with balance
        SizedBox(
          width: 180,
          height: 180,
          child: CustomPaint(
            painter: _ArcPainter(
              progress: 0.72,
              color: const Color(0xFF80DEEA),
              trackColor: Colors.white.withValues(alpha: 0.08),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'Q 8,450',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Balance total',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Monthly trend badge
        Positioned(
          top: 12,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF81C784).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF81C784).withValues(alpha: 0.45),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.trending_up_rounded,
                  size: 13,
                  color: Color(0xFF81C784),
                ),
                SizedBox(width: 4),
                Text(
                  '+12%',
                  style: TextStyle(
                    color: Color(0xFF81C784),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Mini bar chart
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (final double h in <double>[
                0.35,
                0.55,
                0.45,
                0.75,
                0.60,
                0.85,
                0.70,
              ])
                Container(
                  width: 16,
                  height: 48 * h,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF80DEEA).withValues(
                      alpha: 0.3 + h * 0.4,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _ArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 10;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    paint.color = trackColor;
    canvas.drawCircle(center, radius, paint);

    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Step 3: goal card preview with timeline chips ───────────────────────────

class _Step3Illustration extends StatelessWidget {
  const _Step3Illustration();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Goal card mock-up
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCC80).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.flight_takeoff_rounded,
                      size: 22,
                      color: Color(0xFFFFCC80),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Viaje a México',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Q 2,400 de Q 3,500',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    '68%',
                    style: TextStyle(
                      color: Color(0xFFFFCC80),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: 0.68,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: const Color(0xFFFFCC80),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Plazo: 6 meses',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Q 175 / semana',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Preset duration chips
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: <Widget>[
            _TimelineChip('3 meses', Icons.directions_run),
            _TimelineChip('6 meses', Icons.trending_up),
            _TimelineChip('1 año', Icons.star),
            _TimelineChip('2 años', Icons.emoji_events),
          ],
        ),
      ],
    ),
  );
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _NavIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    icon: Icon(icon, color: Colors.white70, size: 20),
    style: IconButton.styleFrom(
      backgroundColor: Colors.white.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class _TimelineChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _TimelineChip(this.label, this.icon);

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 14, color: Colors.white70),
    label: Text(
      label,
      style: const TextStyle(color: Colors.white, fontSize: 12),
    ),
    backgroundColor: Colors.white.withValues(alpha: 0.15),
    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 2),
  );
}

// ── Data class ──────────────────────────────────────────────────────────────

class _OnboardStep {
  final String titleKey;
  final String descriptionKey;
  final String badgeKey;
  final Color accentColor;
  final Widget illustration;

  const _OnboardStep({
    required this.titleKey,
    required this.descriptionKey,
    required this.badgeKey,
    required this.accentColor,
    required this.illustration,
  });
}
