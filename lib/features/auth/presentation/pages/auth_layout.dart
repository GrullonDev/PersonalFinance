import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

import 'package:dartz/dartz.dart' hide State;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:personal_finance/core/services/haptic_feedback_service.dart';
import 'package:personal_finance/core/presentation/widgets/custom_text_field.dart';
import 'package:personal_finance/features/auth/domain/auth_failure.dart';
import 'package:personal_finance/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';
import 'package:personal_finance/utils/routes/route_path.dart';

// Color verde de la app — alineado con el seedColor en main.dart
const _kGreen = Color(0xFF0E8F5B);

class AuthLayout extends StatefulWidget {
  const AuthLayout({super.key});

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout> {
  final _formKey = GlobalKey<FormState>();
  bool _navigating = false;

  @override
  Widget build(BuildContext context) => Consumer<AuthProvider>(
    builder:
        (context, auth, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _buildHeader(context),
            const SizedBox(height: 40),
            _buildGoogleButton(context, auth),
            const SizedBox(height: 28),
            _buildDivider(context),
            const SizedBox(height: 28),
            _buildEmailForm(context, auth),
            const SizedBox(height: 20),
            _buildLoginButton(context, auth),
            const SizedBox(height: 32),
            _buildBottomSection(context, auth),
            const SizedBox(height: 8),
          ],
        ),
  );

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) => Column(
    children: [
      // Icono en contenedor con acento verde
      Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: _kGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kGreen.withValues(alpha: 0.35)),
        ),
        child: const Icon(
          Icons.account_balance_wallet_outlined,
          size: 34,
          color: _kGreen,
        ),
      ),

      const SizedBox(height: 20),

      const Text(
        'Bienvenido',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),

      const SizedBox(height: 6),

      Text(
        'Controla tu dinero en segundos',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 15,
        ),
      ),
    ],
  );

  // ── Botón Google (CTA principal) ──────────────────────────────────────────

  Widget _buildGoogleButton(BuildContext context, AuthProvider auth) =>
      SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: auth.isLoading ? null : () => _handleGoogle(context, auth),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            disabledBackgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ).copyWith(
            // Sombra ligera sin usar elevation para evitar el tinte de color
            overlayColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child:
                auth.isLoading
                    ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icono Google con colores reales (sin ColorFilter)
                        SvgPicture.asset('assets/icons/google.svg', height: 22),
                        const SizedBox(width: 12),
                        Text(
                          'Continuar con Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      );

  Future<void> _handleGoogle(BuildContext context, AuthProvider auth) async {
    await HapticFeedbackService.selection();
    final bool ok = await auth.signInWithGoogle();
    if (!context.mounted) return;
    if (ok) {
      await HapticFeedbackService.success();
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(RoutePath.dashboard, (_) => false);
    } else if (auth.errorMessage != null) {
      await HapticFeedbackService.error();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  // ── Divider ───────────────────────────────────────────────────────────────

  Widget _buildDivider(BuildContext context) {
    final lineColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
    return Row(
      children: [
        Expanded(child: Divider(color: lineColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'o continúa con tu correo',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(child: Divider(color: lineColor, thickness: 1)),
      ],
    );
  }

  // ── Formulario email / contraseña ─────────────────────────────────────────

  Widget _buildEmailForm(BuildContext context, AuthProvider auth) => Form(
    key: _formKey,
    child: Column(
      children: [
        CustomTextField(
          controller: auth.emailController,
          label: 'Correo electrónico',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu correo electrónico';
            }
            if (!RegExp(r'^[^@]+@[^\s]+\.[^\s]+').hasMatch(value)) {
              return 'Por favor ingresa un correo electrónico válido';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: auth.passwordController,
          obscureText: auth.obscurePassword,
          label: 'Contraseña',
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              auth.obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.white.withValues(alpha: 0.5),
              size: 20,
            ),
            onPressed: auth.togglePasswordVisibility,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu contraseña';
            }
            if (value.length < 6) {
              return 'La contraseña debe tener al menos 6 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed:
                () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ForgotPasswordPage(),
                  ),
                ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '¿Olvidaste tu contraseña?',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    ),
  );

  // ── Botón "Iniciar sesión" ─────────────────────────────────────────────────

  Widget _buildLoginButton(BuildContext context, AuthProvider auth) {
    final bool busy = auth.isLoading || _navigating;
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: busy ? null : () => _handleLogin(context, auth),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kGreen,
          disabledBackgroundColor: _kGreen.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: busy
            ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
            : const Text(
              'Iniciar sesión',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context, AuthProvider auth) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await HapticFeedbackService.selection();
    setState(() => _navigating = true);
    final Either<AuthFailure, void> result = await auth.login();
    if (!context.mounted) return;
    await result.fold<Future<void>>(
      (failure) async {
        setState(() => _navigating = false);
        await HapticFeedbackService.error();
        if (failure.statusCode == 403) {
          _showVerificationSheet(context);
        } else if (failure.shouldNavigateToRegister) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              action: SnackBarAction(
                label: 'Crear cuenta',
                textColor: _kGreen,
                onPressed:
                    () => Navigator.pushReplacementNamed(
                      context,
                      RoutePath.register,
                    ),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure.message)));
        }
      },
      (_) async {
        // Fields already cleared by provider; hold the loading indicator
        // for a brief beat so the transition feels intentional.
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!context.mounted) return;
        await HapticFeedbackService.success();
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(RoutePath.dashboard, (_) => false);
      },
    );
  }

  void _showVerificationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => _VerificationBottomSheet(
            email: context.read<AuthProvider>().emailController.text,
          ),
    );
  }

  // ── Sección inferior: registro + Apple ───────────────────────────────────

  Widget _buildBottomSection(BuildContext context, AuthProvider auth) => Column(
    children: [
      // Enlace de registro
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '¿No tienes una cuenta? ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, RoutePath.register),
            style: TextButton.styleFrom(
              foregroundColor: _kGreen,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Crear cuenta',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),

      const SizedBox(height: 20),

      // Apple como opción secundaria discreta
      SizedBox(
        height: 48,
        child: OutlinedButton(
          onPressed: auth.isLoading ? null : () => _handleApple(context, auth),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/apple.svg',
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Continuar con Apple',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Future<void> _handleApple(BuildContext context, AuthProvider auth) async {
    await HapticFeedbackService.selection();
    final bool ok = await auth.signInWithApple();
    if (!context.mounted) return;
    if (ok) {
      await HapticFeedbackService.success();
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(RoutePath.dashboard, (_) => false);
    } else if (auth.errorMessage != null) {
      await HapticFeedbackService.error();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }
}

// ── Bottom Sheet para verificación de email ──────────────────────────────────

class _VerificationBottomSheet extends StatefulWidget {
  const _VerificationBottomSheet({required this.email});
  final String email;

  @override
  State<_VerificationBottomSheet> createState() =>
      _VerificationBottomSheetState();
}

class _VerificationBottomSheetState extends State<_VerificationBottomSheet> {
  bool _resending = false;
  bool _resent = false;

  Future<void> _resendEmail() async {
    setState(() {
      _resending = true;
    });
    try {
      // Iniciar sesión temporalmente para reenviar el correo
      final auth = firebase_auth.FirebaseAuth.instance;
      // Si el usuario ya está autenticado en el SDK (no verificado), reenviar
      final user = auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
      if (mounted) {
        setState(() {
          _resent = true;
          _resending = false;
        });
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _resending = false;
        });
        final String msg =
            e.code == 'too-many-requests'
                ? 'Demasiados intentos. Espera unos minutos antes de reenviar.'
                : 'No se pudo reenviar el correo. Intenta de nuevo más tarde.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo reenviar el correo. Intenta de nuevo más tarde.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono de email
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_unread_outlined,
              color: Colors.amber,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Verifica tu correo electrónico',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                fontSize: 14,
                height: 1.5,
              ),
              children: [
                const TextSpan(
                  text: 'Hemos enviado un correo de verificación a:\n',
                ),
                TextSpan(
                  text: widget.email,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Aviso de spam
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Si no ves el correo en tu bandeja de entrada, '
                    'revisa la carpeta de Spam o Correo no deseado.',
                    style: TextStyle(
                      color: Colors.amber.shade200,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botón reenviar
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: (_resending || _resent) ? null : _resendEmail,
              icon:
                  _resending
                      ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                          ),
                        ),
                      )
                      : Icon(
                        _resent
                            ? Icons.check_circle_outline
                            : Icons.send_outlined,
                        size: 18,
                      ),
              label: Text(
                _resent
                    ? 'Correo reenviado ✓'
                    : _resending
                    ? 'Reenviando…'
                    : 'Reenviar correo de verificación',
                style: const TextStyle(fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    _resent ? _kGreen : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                side: BorderSide(
                  color:
                      _resent
                          ? _kGreen.withValues(alpha: 0.4)
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Botón cerrar
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              child: const Text('Entendido'),
            ),
          ),
        ],
      ),
    ),
  );
}
