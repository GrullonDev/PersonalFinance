import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/subscription/domain/entities/subscription_entity.dart';
import 'package:personal_finance/features/subscription/domain/subscription_constants.dart';
import 'package:personal_finance/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:personal_finance/utils/injection_container.dart';

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => BlocProvider.value(
          value: getIt<SubscriptionBloc>(),
          child: const PaywallPage(),
        ),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<SubscriptionBloc, SubscriptionState>(
        listenWhen: (prev, curr) =>
            curr.purchaseSuccess && !prev.purchaseSuccess,
        listener: (context, state) => Navigator.of(context).pop(true),
        child: _PaywallContent(),
      );
}

class _PaywallContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: Stack(
      children: [
        // Dark gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF020617)],
            ),
          ),
        ),
        // Glow top-left
        Positioned(
          top: -80,
          left: -80,
          child: _GlowCircle(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            size: 280,
          ),
        ),
        // Glow bottom-right
        Positioned(
          bottom: -60,
          right: -60,
          child: _GlowCircle(
            color: const Color(0xFFEC4899).withValues(alpha: 0.25),
            size: 240,
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildHeader(),
                      const SizedBox(height: 28),
                      _buildFeatureList(),
                      const SizedBox(height: 28),
                      _buildPriceCard(),
                      const SizedBox(height: 24),
                      _buildActions(context),
                      const SizedBox(height: 16),
                      _buildFooterLinks(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildTopBar(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    ),
  );

  Widget _buildHeader() => Column(
    children: [
      Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.workspace_premium, color: Colors.white, size: 36),
      ),
      const SizedBox(height: 16),
      const Text(
        'PersonalFinance Pro',
        style: TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Take full control of your finances',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 15,
        ),
      ),
    ],
  );

  Widget _buildFeatureList() => Column(
    children: PlanFeatures.proFeatures
        .map((f) => _FeatureTile(feature: f))
        .toList(),
  );

  Widget _buildPriceCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(
        colors: [
          const Color(0xFF6366F1).withValues(alpha: 0.2),
          const Color(0xFFEC4899).withValues(alpha: 0.15),
        ],
      ),
      border: Border.all(
        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
      ),
    ),
    child: Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '\$',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '5.99',
              style: TextStyle(
                color: Colors.white,
                fontSize: 52,
                fontWeight: FontWeight.bold,
                height: 1,
                letterSpacing: -2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'per month · cancel anytime',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 13,
          ),
        ),
      ],
    ),
  );

  Widget _buildActions(BuildContext context) =>
      BlocBuilder<SubscriptionBloc, SubscriptionState>(
        builder: (context, state) => Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: state.isPurchasing
                      ? null
                      : () => context
                            .read<SubscriptionBloc>()
                            .add(SubscriptionPurchasePro()),
                  child: state.isPurchasing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Get Pro Now',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: state.isRestoring
                  ? null
                  : () => context
                        .read<SubscriptionBloc>()
                        .add(SubscriptionRestore()),
              child: state.isRestoring
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white54,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Restore purchases',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 14,
                      ),
                    ),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );

  Widget _buildFooterLinks(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _FooterLink(
        label: 'Terms of Use',
        onTap: () {/* TODO: abrir URL de términos */},
      ),
      Text(
        '  ·  ',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      ),
      _FooterLink(
        label: 'Privacy Policy',
        onTap: () {/* TODO: abrir URL de privacidad */},
      ),
    ],
  );
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature});
  final PlanFeature feature;

  @override
  Widget build(BuildContext context) {
    final label = PlanFeatureLabels.labels[feature];
    if (label == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
              ),
            ),
            child: SizedBox(
              width: 28,
              height: 28,
              child: Icon(Icons.check, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  label.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
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

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Text(
      label,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 12,
        decoration: TextDecoration.underline,
        decorationColor: Colors.white.withValues(alpha: 0.25),
      ),
    ),
  );
}
