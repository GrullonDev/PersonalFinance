import 'package:flutter/material.dart';

import 'package:dartz/dartz.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:personal_finance/core/presentation/widgets/custom_text_field.dart';
import 'package:personal_finance/features/auth/domain/auth_failure.dart';
import 'package:personal_finance/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';
import 'package:personal_finance/utils/routes/route_path.dart';

// Color verde de la app — alineado con el seedColor en main.dart
const _kGreen = Color(0xFF0E8F5B);

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) => Column(
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
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Icono en contenedor con acento verde
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _kGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kGreen.withOpacity(0.35), width: 1),
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
            color: Colors.white.withOpacity(0.5),
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  // ── Botón Google (CTA principal) ──────────────────────────────────────────

  Widget _buildGoogleButton(BuildContext context, AuthProvider auth) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: auth.isLoading ? null : () => _handleGoogle(context, auth),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          disabledBackgroundColor: Colors.white.withOpacity(0.7),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ).copyWith(
          // Sombra ligera sin usar elevation para evitar el tinte de color
          overlayColor: WidgetStateProperty.all(Colors.grey.withOpacity(0.08)),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: auth.isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1F1F1F)),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono Google con colores reales (sin ColorFilter)
                    SvgPicture.asset('assets/icons/google.svg', height: 22),
                    const SizedBox(width: 12),
                    const Text(
                      'Continuar con Google',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _handleGoogle(BuildContext context, AuthProvider auth) async {
    final bool ok = await auth.signInWithGoogle();
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        RoutePath.dashboard,
        (_) => false,
      );
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!)),
      );
    }
  }

  // ── Divider ───────────────────────────────────────────────────────────────

  Widget _buildDivider(BuildContext context) {
    final lineColor = Colors.white.withOpacity(0.12);
    return Row(
      children: [
        Expanded(child: Divider(color: lineColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'o continúa con tu correo',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(child: Divider(color: lineColor, thickness: 1)),
      ],
    );
  }

  // ── Formulario email / contraseña ─────────────────────────────────────────

  Widget _buildEmailForm(BuildContext context, AuthProvider auth) {
    return Form(
      key: auth.formKey,
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
                color: Colors.white.withOpacity(0.5),
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
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ForgotPasswordPage(),
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.5),
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
  }

  // ── Botón "Iniciar sesión" ─────────────────────────────────────────────────

  Widget _buildLoginButton(BuildContext context, AuthProvider auth) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: auth.isLoading ? null : () => _handleLogin(context, auth),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kGreen,
          disabledBackgroundColor: _kGreen.withOpacity(0.4),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: auth.isLoading
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
    final Either<AuthFailure, void> result = await auth.login();
    if (!context.mounted) return;
    result.fold(
      (failure) {
        if (failure.shouldNavigateToRegister) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              action: SnackBarAction(
                label: 'Crear cuenta',
                textColor: _kGreen,
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  RoutePath.register,
                ),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        }
      },
      (_) => Navigator.of(context).pushNamedAndRemoveUntil(
        RoutePath.dashboard,
        (_) => false,
      ),
    );
  }

  // ── Sección inferior: registro + Apple ───────────────────────────────────

  Widget _buildBottomSection(BuildContext context, AuthProvider auth) {
    return Column(
      children: [
        // Enlace de registro
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿No tienes una cuenta? ',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, RoutePath.register),
              style: TextButton.styleFrom(
                foregroundColor: _kGreen,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Crear cuenta',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Apple como opción secundaria discreta
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed:
                auth.isLoading ? null : () => _handleApple(context, auth),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.15)),
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
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleApple(BuildContext context, AuthProvider auth) async {
    final bool ok = await auth.signInWithApple();
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        RoutePath.dashboard,
        (_) => false,
      );
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!)),
      );
    }
  }
}
