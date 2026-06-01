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
      accentColor: Color(0xFF4EDEA3),
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
      accentColor: Color(0xFF4EDEA3),
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
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: <Widget>[
                // Brand logo
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4EDEA3).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        size: 16,
                        color: Color(0xFF4EDEA3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loc.appTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
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
            flex: 52,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (int i) => setState(() => _index = i),
              itemCount: _steps.length,
              itemBuilder: (BuildContext _, int i) => _steps[i].illustration,
            ),
          ),

          // ── Text content ────────────────────────────────────────
          Expanded(
            flex: 48,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
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
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    loc.translate(step.titleKey),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.15,
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
                      height: 1.55,
                    ),
                  ),

                  // Feature pills — only step 1
                  if (_index == 0) ...<Widget>[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _FeaturePill(
                          icon: Icons.sync_rounded,
                          label: loc.step1Pill1,
                          color: step.accentColor,
                        ),
                        _FeaturePill(
                          icon: Icons.insights_rounded,
                          label: loc.step1Pill2,
                          color: step.accentColor,
                        ),
                      ],
                    ),
                  ],

                  const Spacer(),

                  // Navigation row
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: <Widget>[
                        Row(
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
                                          ? step.accentColor
                                          : Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),

                            // Step counter text
                            Text(
                              '${_index + 1} de ${_steps.length}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
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
                                foregroundColor: const Color(0xFF002113),
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
                                    isLast ? loc.getStartedNow : loc.next,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
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

                        // Secondary action — last screen only
                        if (isLast) ...<Widget>[
                          const SizedBox(height: 14),
                          Center(
                            child: TextButton(
                              onPressed: _complete,
                              child: Text(
                                loc.alreadyHaveAccount,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
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

// ── Step 1: floating transaction cards + feature pills ──────────────────────

class _Step1Illustration extends StatelessWidget {
  const _Step1Illustration();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // Radial glow
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                const Color(0xFF4EDEA3).withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            size: 64,
            color: Color(0xFF4EDEA3),
          ),
        ),

        // Floating badge — top right
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF4EDEA3).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4EDEA3).withValues(alpha: 0.45),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.trending_up_rounded,
                  size: 13,
                  color: Color(0xFF4EDEA3),
                ),
                SizedBox(width: 4),
                Text(
                  '+12.5%',
                  style: TextStyle(
                    color: Color(0xFF4EDEA3),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
            color: const Color(0xFF4EDEA3).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: const Color(0xFF4EDEA3)),
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
                        ? const Color(0xFF4EDEA3)
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

// ── Step 2: debt-free freedom illustration ──────────────────────────────────

class _Step2Illustration extends StatelessWidget {
  const _Step2Illustration();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // Central glow ring
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                const Color(0xFF80DEEA).withValues(alpha: 0.25),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // Center icon — person breaking free
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.07),
            border: Border.all(
              color: const Color(0xFF80DEEA).withValues(alpha: 0.35),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.directions_run_rounded,
            size: 40,
            color: Color(0xFF80DEEA),
          ),
        ),

        // Broken chain links — left
        const Positioned(
          left: 8,
          top: 40,
          child: _ChainLink(angle: -0.4, color: Color(0xFF80DEEA)),
        ),
        Positioned(
          left: 28,
          top: 22,
          child: _ChainLink(angle: -0.8, color: const Color(0xFF80DEEA).withValues(alpha: 0.6)),
        ),

        // Broken chain links — right
        const Positioned(
          right: 8,
          top: 40,
          child: _ChainLink(angle: 0.4, color: Color(0xFF80DEEA)),
        ),
        Positioned(
          right: 28,
          top: 22,
          child: _ChainLink(angle: 0.8, color: const Color(0xFF80DEEA).withValues(alpha: 0.6)),
        ),

        // Debt-cleared badges — bottom area
        const Positioned(
          bottom: 20,
          left: 0,
          child: _DebtChip(label: 'Tarjeta: Q 0', cleared: true),
        ),
        const Positioned(
          bottom: 20,
          right: 0,
          child: _DebtChip(label: 'Préstamo: Q 0', cleared: true),
        ),

        // Sparkle accents
        Positioned(
          top: 12,
          left: 60,
          child: Icon(
            Icons.star_rounded,
            size: 14,
            color: const Color(0xFF80DEEA).withValues(alpha: 0.6),
          ),
        ),
        Positioned(
          top: 18,
          right: 56,
          child: Icon(
            Icons.star_rounded,
            size: 10,
            color: const Color(0xFF80DEEA).withValues(alpha: 0.4),
          ),
        ),
      ],
    ),
  );
}

class _ChainLink extends StatelessWidget {
  final double angle;
  final Color color;

  const _ChainLink({required this.angle, required this.color});

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: 24,
      height: 14,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color, width: 2.5),
      ),
    ),
  );
}

class _DebtChip extends StatelessWidget {
  final String label;
  final bool cleared;

  const _DebtChip({required this.label, required this.cleared});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFF4EDEA3).withValues(alpha: 0.4),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Icons.check_circle_rounded,
          size: 13,
          color: const Color(0xFF4EDEA3),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4EDEA3),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

// ── Step 3: goal card preview + achievement floating card ───────────────────

class _Step3Illustration extends StatelessWidget {
  const _Step3Illustration();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? loc = AppLocalizations.of(context);
    final String achievement = loc?.step3Achievement ?? 'Meta alcanzada';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Stack(
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Goal card mock-up
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF4EDEA3).withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4EDEA3).withValues(
                              alpha: 0.18,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.savings_rounded,
                            size: 22,
                            color: Color(0xFF4EDEA3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Fondo de Emergencia',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Q 8,400 de Q 10,000',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          '84%',
                          style: TextStyle(
                            color: Color(0xFF4EDEA3),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: 0.84,
                        minHeight: 7,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        color: const Color(0xFF4EDEA3),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Plazo: 3 meses',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Q 200 / semana',
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
              const SizedBox(height: 16),

              // Mini goals row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _MiniGoalChip(
                    icon: Icons.flight_takeoff_rounded,
                    label: 'Viaje',
                    progress: 0.62,
                  ),
                  _MiniGoalChip(
                    icon: Icons.home_rounded,
                    label: 'Casa',
                    progress: 0.35,
                  ),
                  _MiniGoalChip(
                    icon: Icons.school_rounded,
                    label: 'Educación',
                    progress: 0.88,
                  ),
                ],
              ),
            ],
          ),

          // Floating achievement card — top right
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF4EDEA3).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF4EDEA3).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 16,
                    color: Color(0xFF4EDEA3),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Libertad Financiera',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        achievement,
                        style: const TextStyle(
                          color: Color(0xFF4EDEA3),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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

class _MiniGoalChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final double progress;

  const _MiniGoalChip({
    required this.icon,
    required this.label,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18, color: const Color(0xFF4EDEA3)),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 48,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              color: const Color(0xFF4EDEA3),
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

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
