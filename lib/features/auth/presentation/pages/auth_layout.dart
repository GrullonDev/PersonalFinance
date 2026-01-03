import 'package:flutter/material.dart';

import 'package:dartz/dartz.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

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
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 55),
                  _buildLogoAndWelcome(context),
                  _buildEmailAndPasswordFields(context, authProvider),
                  const SizedBox(height: 24),
                  _buildLoginButton(context, authProvider),
                  const SizedBox(height: 24),
                  _buildSocialLoginOptions(context, authProvider),
                  _buildSignUpLink(context),
                ],
              ),
            ),
  );

  Widget _buildLogoAndWelcome(BuildContext context) => Column(
    children: <Widget>[
      Container(
        width: 120,
        height: 120,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue,
        ),
        child: const Icon(
          Icons.account_balance_wallet,
          size: 60,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Bienvenido de nuevo',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      Text(
        'Inicia sesión para continuar',
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
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
        TextFormField(
          controller: authProvider.emailController,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
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
        TextFormField(
          controller: authProvider.passwordController,
          obscureText: authProvider.obscurePassword,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                authProvider.obscurePassword
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: authProvider.togglePasswordVisibility,
            ),
            border: const OutlineInputBorder(),
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
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
        ),
      ],
    ),
  );

  Widget _buildLoginButton(
    BuildContext context,
    AuthProvider authProvider,
  ) => SizedBox(
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
                      // Show a snackbar with an action to navigate to register
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(failure.message),
                          action: SnackBarAction(
                            label: 'Crear cuenta',
                            textColor: Colors.blue,
                            onPressed: () {
                              // Navigate to the registration screen
                              // Replace with your actual registration route
                              Navigator.pushReplacementNamed(
                                context,
                                RoutePath
                                    .register, // Make sure this route is defined in your RoutePath
                              );
                            },
                          ),
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    } else {
                      // Show regular error message
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(failure.message)));
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child:
          authProvider.isLoading
              ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
              : const Text('Iniciar sesión', style: TextStyle(fontSize: 16)),
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
        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
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
      const Text('¿No tienes una cuenta? '),
      TextButton(
        onPressed: () {
          Navigator.pushNamed(context, RoutePath.register);
        },
        child: const Text('Regístrate'),
      ),
    ],
  );

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required String icon,
  }) => IconButton(
    onPressed: onPressed,
    icon: SvgPicture.asset(icon, height: 24),
  );
}
