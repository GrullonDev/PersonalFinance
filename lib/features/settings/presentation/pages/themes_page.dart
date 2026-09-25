import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/settings/presentation/providers/settings_provider.dart';
import 'package:personal_finance/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:personal_finance/features/subscription/presentation/pages/paywall_page.dart';
import 'package:personal_finance/utils/app_theme_preset.dart';
import 'package:personal_finance/utils/injection_container.dart';
class ThemesPage extends StatelessWidget {
  const ThemesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      bloc: getIt<SubscriptionBloc>(),
      builder: (context, subState) {
        final isPro = subState.isPremium;
        final freePresets =
            AppThemePreset.all.where((p) => !p.isPremium).toList();
        final premiumPresets =
            AppThemePreset.all.where((p) => p.isPremium).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Temas')),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              _CurrentThemeBanner(settings: settings),
              const _SectionHeader(label: 'TEMAS GRATUITOS'),
              _ThemeGrid(
                presets: freePresets,
                selectedId: settings.selectedThemeId,
                isPro: true,
                onSelect: (id) => settings.setThemeId(id),
                onLocked: (_) {},
              ),
              const SizedBox(height: 8),
              _PremiumSectionHeader(isPro: isPro),
              if (!isPro) _UpgradeHint(onTap: () => PaywallPage.show(context)),
              _ThemeGrid(
                presets: premiumPresets,
                selectedId: settings.selectedThemeId,
                isPro: isPro,
                onSelect: (id) => settings.setThemeId(id),
                onLocked: (_) => PaywallPage.show(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Current theme banner ────────────────────────────────────────────────────

class _CurrentThemeBanner extends StatelessWidget {
  const _CurrentThemeBanner({required this.settings});
  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final current = AppThemePreset.getById(settings.selectedThemeId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            _ColorDot(color: current.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tema actual',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    current.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: current.isDark
                    ? const Color(0xFF1E1B4B)
                    : const Color(0xFFFEF9C3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    current.isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    size: 13,
                    color: current.isDark
                        ? const Color(0xFFA5B4FC)
                        : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    current.isDark ? 'Oscuro' : 'Claro',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: current.isDark
                          ? const Color(0xFFA5B4FC)
                          : const Color(0xFFD97706),
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

// ── Section headers ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class _PremiumSectionHeader extends StatelessWidget {
  const _PremiumSectionHeader({required this.isPro});
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Text(
            'TEMAS PREMIUM',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isPro ? 'ACTIVO' : 'PRO',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeHint extends StatelessWidget {
  const _UpgradeHint({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6366F1).withValues(alpha: 0.1),
              const Color(0xFFEC4899).withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 16,
              color: Color(0xFF6366F1),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Desbloquea 6 temas exclusivos con Pro',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Color(0xFF6366F1),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Theme grid ───────────────────────────────────────────────────────────────

class _ThemeGrid extends StatelessWidget {
  const _ThemeGrid({
    required this.presets,
    required this.selectedId,
    required this.isPro,
    required this.onSelect,
    required this.onLocked,
  });

  final List<AppThemePreset> presets;
  final String selectedId;
  final bool isPro;
  final void Function(String id) onSelect;
  final void Function(String id) onLocked;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: presets.length,
      itemBuilder: (context, i) {
        final preset = presets[i];
        final isSelected = selectedId == preset.id;
        final isLocked = preset.isPremium && !isPro;
        return _ThemeCard(
          preset: preset,
          isSelected: isSelected,
          isLocked: isLocked,
          onTap: () => isLocked ? onLocked(preset.id) : onSelect(preset.id),
        );
      },
    ),
  );
}

// ── Theme card ───────────────────────────────────────────────────────────────

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.preset,
    required this.isSelected,
    required this.isLocked,
    required this.onTap,
  });

  final AppThemePreset preset;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: preset.previewSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? preset.primary
                : cs.outlineVariant.withValues(alpha: 0.4),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? preset.primary.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: isSelected ? 14 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Color preview area ────────────────────────────────────
                Expanded(
                  flex: 7,
                  child: _PreviewArea(preset: preset),
                ),
                // ── Label row ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(11, 7, 11, 9),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preset.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: cs.onSurface,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  preset.isDark
                                      ? Icons.dark_mode_rounded
                                      : Icons.light_mode_rounded,
                                  size: 10,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  preset.isDark ? 'Oscuro' : 'Claro',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: preset.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // ── PRO badge ─────────────────────────────────────────────────
            if (preset.isPremium)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // ── Lock overlay ──────────────────────────────────────────────
            if (isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Preview area inside the card ─────────────────────────────────────────────

class _PreviewArea extends StatelessWidget {
  const _PreviewArea({required this.preset});
  final AppThemePreset preset;

  @override
  Widget build(BuildContext context) {
    final bg = preset.previewBackground;
    final surf = preset.previewSurface;
    final primary = preset.primary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(17),
          topRight: Radius.circular(17),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // mock app bar line
          Row(
            children: [
              Container(
                width: 28,
                height: 3.5,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Spacer(),
              _ColorDot(color: primary, size: 10),
            ],
          ),
          const SizedBox(height: 7),
          // mock balance card
          Container(
            height: 26,
            decoration: BoxDecoration(
              color: surf.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(7),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 5,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 20,
                  height: 5,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          // mock two small cards
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 20,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: surf.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // mock action button
          Container(
            height: 7,
            width: 36,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
