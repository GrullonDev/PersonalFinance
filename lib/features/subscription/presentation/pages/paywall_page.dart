import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/subscription/data/datasources/revenue_cat_service.dart';
import 'package:personal_finance/features/subscription/domain/entities/subscription_entity.dart';
import 'package:personal_finance/features/subscription/domain/subscription_constants.dart';
import 'package:personal_finance/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:personal_finance/utils/app_localization.dart';
import 'package:personal_finance/utils/injection_container.dart';

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder:
            (_, __, ___) => BlocProvider.value(
              value: getIt<SubscriptionBloc>(),
              child: const PaywallPage(),
            ),
        transitionsBuilder:
            (_, animation, __, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<SubscriptionBloc, SubscriptionState>(
        listenWhen:
            (prev, curr) => curr.purchaseSuccess && !prev.purchaseSuccess,
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
                      _buildHeader(context),
                      const SizedBox(height: 28),
                      _buildFeatureList(context),
                      const SizedBox(height: 24),
                      const _ComparisonTable(),
                      const SizedBox(height: 24),
                      _buildPriceCard(context),
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

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
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
          child: const Icon(
            Icons.workspace_premium,
            color: Colors.white,
            size: 36,
          ),
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
          l10n?.paywallSubtitle ?? 'Take full control of your finances',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureList(BuildContext context) => Column(
    children:
        PlanFeatures.proFeatures.map((f) => _FeatureTile(feature: f)).toList(),
  );

  Widget _buildPriceCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
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
          FutureBuilder<String?>(
            future: _price ??= _storePrice(),
            builder:
                (context, snap) => Text(
                  snap.data ?? PlanPricing.proMonthlyFormatted,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    height: 1,
                    letterSpacing: -1.5,
                  ),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n?.paywallPerMonth ?? 'per month · cancel anytime',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  static Future<String?>? _price;

  /// Precio que cobrará la tienda en la moneda del usuario.
  Future<String?> _storePrice() async {
    if (!getIt.isRegistered<RevenueCatService>()) return null;
    return getIt<RevenueCatService>().monthlyPriceString().timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );
  }

  Widget _buildActions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder:
          (context, state) => Column(
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
                    onPressed:
                        state.isPurchasing
                            ? null
                            : () => context.read<SubscriptionBloc>().add(
                              SubscriptionPurchasePro(),
                            ),
                    child:
                        state.isPurchasing
                            ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                            : Text(
                              l10n?.paywallGetPro ?? 'Get Pro Now',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed:
                    state.isRestoring
                        ? null
                        : () => context.read<SubscriptionBloc>().add(
                          SubscriptionRestore(),
                        ),
                child:
                    state.isRestoring
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white54,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          l10n?.paywallRestore ?? 'Restore purchases',
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
  }

  Widget _buildFooterLinks(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FooterLink(
          label: l10n?.paywallTerms ?? 'Terms of Use',
          onTap: () {
            /* TODO: abrir URL de términos */
          },
        ),
        Text(
          '  ·  ',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        ),
        _FooterLink(
          label: l10n?.paywallPrivacy ?? 'Privacy Policy',
          onTap: () {
            /* TODO: abrir URL de privacidad */
          },
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature});
  final PlanFeature feature;

  @override
  Widget build(BuildContext context) {
    final languageCode =
        AppLocalizations.of(context)?.locale.languageCode ?? 'es';
    final label = PlanFeatureLabels.labelsFor(languageCode)[feature];
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

/// Qué incluye cada plan, para que quede claro qué se gana con Pro.
class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable();

  @override
  Widget build(BuildContext context) {
    final languageCode =
        AppLocalizations.of(context)?.locale.languageCode ?? 'es';
    final isEs = languageCode == 'es';
    final muted = Colors.white.withValues(alpha: 0.55);
    final header = TextStyle(
      color: muted,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    Widget cell(String? value, {required bool pro}) {
      if (value == null) {
        return Icon(
          Icons.remove,
          color: Colors.white.withValues(alpha: 0.3),
          size: 16,
        );
      }
      if (value.isEmpty) {
        return Icon(
          Icons.check_circle,
          color: pro ? const Color(0xFFEC4899) : Colors.white70,
          size: 18,
        );
      }
      return Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: pro ? Colors.white : muted,
          fontSize: 12,
          fontWeight: pro ? FontWeight.w600 : FontWeight.normal,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isEs ? 'Qué incluye' : 'What you get',
                  style: header,
                ),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  isEs ? 'Gratis' : 'Free',
                  textAlign: TextAlign.center,
                  style: header,
                ),
              ),
              const SizedBox(
                width: 84,
                child: Text(
                  'Pro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFEC4899),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final row in PlanComparison.rows(languageCode))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: Center(child: cell(row.free, pro: false)),
                  ),
                  SizedBox(
                    width: 84,
                    child: Center(child: cell(row.pro, pro: true)),
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
