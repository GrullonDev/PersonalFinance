import 'package:flutter/material.dart';

import 'package:dartz/dartz.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:personal_finance/core/presentation/widgets/custom_text_field.dart';
import 'package:personal_finance/core/presentation/widgets/glass_container.dart';
import 'package:personal_finance/features/auth/domain/auth_failure.dart';
import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';
import 'package:personal_finance/utils/routes/route_path.dart';
import 'package:personal_finance/features/auth/presentation/pages/forgot_password_page.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key});

  @override
  Widget build(BuildContext context) => Consumer<AuthProvider>(
    builder:
        (BuildContext context, AuthProvider authProvider, Widget? child) =>
            GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 16),
                  _buildLogoAndWelcome(context),
                  _buildEmailAndPasswordFields(context, authProvider),
                  const SizedBox(height: 24),
                  _buildLoginButton(context, authProvider),
                  const SizedBox(height: 24),
                  _buildSocialLoginOptions(context, authProvider),
                  _buildSignUpLink(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
  );

  Widget _buildLogoAndWelcome(BuildContext context) => Column(
    children: <Widget>[
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(
          Icons.account_balance_wallet,
          size: 50,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Bienvenido de nuevo',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Inicia sesión para continuar',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
      ),
      const SizedBox(height: 32),
    ],
  );

  Widget _buildEmailAndPasswordFields(
    BuildContext context,
    AuthProvider authProvider,
  ) => Form(
    key: authProvider.formKey,
    child: Column(
      children: <Widget>[
        CustomTextField(
          controller: authProvider.emailController,
          label: 'Correo electrónico',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu correo electrónico';
            }
            if (!RegExp(r'^[^@]+@[^\s]+\.[^\s]+').hasMatch(value)) {
              return 'Por favor ingresa un correo electrónico válido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: authProvider.passwordController,
          obscureText: authProvider.obscurePassword,
          label: 'Contraseña',
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              authProvider.obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.white70,
            ),
            onPressed: authProvider.togglePasswordVisibility,
          ),
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu contraseña';
            }
            if (value.length < 6) {
              return 'La contraseña debe tener al menos 6 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.push<dynamic>(
                context,
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) => const ForgotPasswordPage(),
                ),
              );
            },
            child: const Text(
              '¿Olvidaste tu contraseña?',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildLoginButton(BuildContext context, AuthProvider authProvider) =>
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed:
              authProvider.isLoading
                  ? null
                  : () async {
                    final Either<AuthFailure, void> result =
                        await authProvider.login();
                    result.fold(
                      (AuthFailure failure) {
                        if (failure.shouldNavigateToRegister) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(failure.message),
                              action: SnackBarAction(
                                label: 'Crear cuenta',
                                textColor: Colors.blue,
                                onPressed: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    RoutePath.register,
                                  );
                                },
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
                      (_) {
                        Navigator.pushReplacementNamed(
                          context,
                          RoutePath.dashboard,
                        );
                      },
                    );
                  },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.blue.withOpacity(0.5),
          ),
          child:
              authProvider.isLoading
                  ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                  : const Text(
                    'Iniciar sesión',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
        ),
      );

  Widget _buildSocialLoginOptions(
    BuildContext context,
    AuthProvider authProvider,
  ) => Column(
    children: <Widget>[
      Text(
        'O inicia sesión con',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.white60),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _buildSocialButton(
            onPressed: () async {
              final bool result = await authProvider.signInWithGoogle();
              if (result) {
                Navigator.pushReplacementNamed(context, RoutePath.dashboard);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(authProvider.errorMessage!)),
                );
              }
            },
            icon: 'assets/icons/google.svg',
          ),
          const SizedBox(width: 24),
          _buildSocialButton(
            onPressed: () async {
              final bool result = await authProvider.signInWithApple();
              if (result) {
                Navigator.pushReplacementNamed(context, RoutePath.dashboard);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(authProvider.errorMessage!)),
                );
              }
            },
            icon: 'assets/icons/apple.svg',
          ),
        ],
      ),
      const SizedBox(height: 24),
    ],
  );

  Widget _buildSignUpLink(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      const Text(
        '¿No tienes una cuenta? ',
        style: TextStyle(color: Colors.white70),
      ),
      TextButton(
        onPressed: () {
          Navigator.pushNamed(context, RoutePath.register);
        },
        child: const Text(
          'Regístrate',
          style: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required String icon,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withOpacity(0.2)),
    ),
    child: IconButton(
      onPressed: onPressed,
      icon: SvgPicture.asset(
        icon,
        height: 24,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    ),
  );
}
