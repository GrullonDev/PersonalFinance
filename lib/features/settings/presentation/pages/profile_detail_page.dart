import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';
import 'package:personal_finance/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:personal_finance/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:personal_finance/features/profile/domain/repositories/profile_backend_repository.dart';
import 'package:personal_finance/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:personal_finance/features/subscription/presentation/pages/paywall_page.dart';
import 'package:personal_finance/utils/app_localization.dart';
import 'package:personal_finance/utils/injection_container.dart';

class ProfileDetailPage extends StatelessWidget {
  const ProfileDetailPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<ProfileBloc>(
    create:
        (_) =>
            ProfileBloc(getIt<ProfileBackendRepository>())
              ..add(ProfileLoadMe()),
    child: const ProfileDetailView(),
  );
}

class ProfileDetailView extends StatelessWidget {
  const ProfileDetailView({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<ProfileBloc, ProfileState>(
    builder: (BuildContext context, ProfileState state) {
      if (state.loading) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Perfil'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      final authUser = context.watch<AuthProvider>().currentUser;
      final String fullName =
          (state.info?.fullName != null && state.info!.fullName.isNotEmpty)
              ? state.info!.fullName
              : (authUser?.fullName != null && authUser!.fullName.isNotEmpty
                  ? authUser.fullName
                  : 'Usuario');
      final String email =
          (state.info?.email != null && state.info!.email.isNotEmpty)
              ? state.info!.email
              : (authUser?.email ?? '');
      final String phoneNumber =
          (state.info?.phoneNumber != null &&
                  state.info!.phoneNumber!.isNotEmpty)
              ? state.info!.phoneNumber!
              : (authUser?.phoneNumber != null &&
                      authUser!.phoneNumber!.isNotEmpty
                  ? authUser.phoneNumber!
                  : 'No especificado');
      final String? photoUrl =
          (state.info?.photoUrl != null && state.info!.photoUrl!.isNotEmpty)
              ? state.info!.photoUrl
              : authUser?.photoUrl;

      return Scaffold(
        appBar: AppBar(
          title: const Text('Perfil'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Profile picture / initials avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child:
                        photoUrl != null && photoUrl.isNotEmpty
                            ? (photoUrl.contains('://')
                                ? ClipOval(
                                  child: Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => _buildInitialsAvatar(
                                          context,
                                          fullName,
                                        ),
                                  ),
                                )
                                : Center(
                                  child: Text(
                                    photoUrl,
                                    style: const TextStyle(fontSize: 48),
                                  ),
                                ))
                            : _buildInitialsAvatar(context, fullName),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const _PlanStatusCard(),
                  const SizedBox(height: 32),

                  // Profile fields card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildProfileField(
                            context,
                            label: 'Nombre Completo',
                            value: fullName,
                            icon: Icons.person_outline,
                          ),
                          const Divider(height: 24),
                          _buildProfileField(
                            context,
                            label: 'Correo electrónico',
                            value: email,
                            icon: Icons.email_outlined,
                          ),
                          const Divider(height: 24),
                          _buildProfileField(
                            context,
                            label: 'Teléfono',
                            value: phoneNumber,
                            icon: Icons.phone_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar Perfil'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final bloc = context.read<ProfileBloc>();
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder:
                                (BuildContext context) =>
                                    BlocProvider<ProfileBloc>.value(
                                      value: bloc,
                                      child: const EditProfilePage(),
                                    ),
                          ),
                        ).then((_) {
                          bloc.add(ProfileLoadMe());
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _buildInitialsAvatar(BuildContext context, String name) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final initials = _getInitials(name);
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final List<String> parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Widget _buildProfileField(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: <Widget>[
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    ),
  );
}

// ── Plan status card ──────────────────────────────────────────────────────────

class _PlanStatusCard extends StatelessWidget {
  const _PlanStatusCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      bloc: getIt<SubscriptionBloc>(),
      builder: (_, state) =>
          state.isPremium ? const _ProCard() : const _FreeCard(),
    );
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEs = l10n?.locale.languageCode == 'es';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.workspace_premium, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      isEs ? 'Plan Pro' : 'Pro Plan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF34C759).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  isEs ? 'Activo' : 'Active',
                  style: const TextStyle(
                    color: Color(0xFF34C759),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isEs
                ? 'Tienes acceso a todas las funciones premium'
                : 'You have access to all premium features',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FeatureChip(
                icon: Icons.chat_rounded,
                label: isEs ? 'Asistente IA' : 'AI Assistant',
              ),
              _FeatureChip(
                icon: Icons.bar_chart_rounded,
                label: isEs ? 'Reportes IA' : 'AI Reports',
              ),
              _FeatureChip(
                icon: Icons.all_inclusive_rounded,
                label: isEs ? 'Sin límites' : 'Unlimited',
              ),
              _FeatureChip(
                icon: Icons.download_rounded,
                label: isEs ? 'Exportar' : 'Export',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FreeCard extends StatelessWidget {
  const _FreeCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEs = l10n?.locale.languageCode == 'es';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey.shade200,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline, color: Colors.grey.shade600, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      isEs ? 'Plan Gratuito' : 'Free Plan',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  isEs ? 'Activo' : 'Active',
                  style: const TextStyle(
                    color: Color(0xFF007AFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isEs
                ? 'Tienes acceso limitado. Actualiza a Pro para desbloquear todas las funciones.'
                : 'You have limited access. Upgrade to Pro to unlock all features.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.workspace_premium, size: 18),
                label: Text(
                  isEs ? 'Actualizar a Pro — \$5.99/mes' : 'Upgrade to Pro — \$5.99/mo',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => PaywallPage.show(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF818CF8)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF818CF8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
