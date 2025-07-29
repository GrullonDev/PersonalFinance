import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:personal_finance/features/auth/data/firebase_auth_service.dart';
import 'package:personal_finance/utils/routes/route_path.dart';
import 'package:personal_finance/utils/validators.dart';

class LoginLayout extends StatelessWidget {
  LoginLayout({super.key});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuthService authService = FirebaseAuthService();

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDarkMode
                  ? <Color>[
                    colorScheme.primary.withValues(alpha: 0.8),
                    colorScheme.secondary.withValues(alpha: 0.8),
                  ]
                  : <Color>[
                    const Color(0xFF4CAF50), // Verde
                    const Color(0xFF2196F3), // Azul
                  ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset('assets/logo.png', height: 100),
              const SizedBox(height: 20),
              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? colorScheme.onPrimary : Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                style: TextStyle(
                  color: isDarkMode ? colorScheme.onSurface : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: 'Email o Usuario',
                  hintText: 'Ingresa tu email o nombre de usuario',
                  labelStyle: TextStyle(
                    color:
                        isDarkMode
                            ? colorScheme.onSurface.withValues(alpha: 0.7)
                            : Colors.black54,
                  ),
                  hintStyle: TextStyle(
                    color:
                        isDarkMode
                            ? colorScheme.onSurface.withValues(alpha: 0.5)
                            : Colors.black38,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDarkMode ? colorScheme.outline : Colors.grey,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDarkMode ? colorScheme.outline : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? colorScheme.surface : Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: TextStyle(
                  color: isDarkMode ? colorScheme.onSurface : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(
                    color:
                        isDarkMode
                            ? colorScheme.onSurface.withValues(alpha: 0.7)
                            : Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDarkMode ? colorScheme.outline : Colors.grey,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDarkMode ? colorScheme.outline : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? colorScheme.surface : Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    // Implementar recuperación de contraseña
                  },
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: isDarkMode ? colorScheme.onPrimary : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Validar campos antes de enviar
                    final String? emailOrUsernameError = AppValidators.validateEmailOrUsername(
                      emailController.text,
                    );
                    final String? passwordError = AppValidators.validateRequired(
                      passwordController.text,
                      'Contraseña',
                    );

                    if (emailOrUsernameError != null || passwordError != null) {
                      final List<String> errors = <String>[
                        if (emailOrUsernameError != null) emailOrUsernameError,
                        if (passwordError != null) passwordError,
                      ];
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(errors.join('\n'))),
                        );
                      }
                      return;
                    }

                    try {
                      final User? user = await authService.loginUser(
                        emailController.text.trim(),
                        passwordController.text,
                      );
                      if (user != null) {
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(
                            context,
                            RoutePath.dashboard,
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Credenciales inválidas'),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        String errorMessage = 'Error al iniciar sesión';
                        
                        if (e.toString().contains('Usuario no encontrado')) {
                          errorMessage = 'Usuario no encontrado';
                        } else if (e.toString().contains('wrong-password')) {
                          errorMessage = 'Contraseña incorrecta';
                        } else if (e.toString().contains('user-not-found')) {
                          errorMessage = 'Usuario no encontrado';
                        } else if (e.toString().contains('invalid-email')) {
                          errorMessage = 'Email inválido';
                        } else if (e.toString().contains('too-many-requests')) {
                          errorMessage = 'Demasiados intentos. Intenta más tarde';
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(errorMessage)),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Log in',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, RoutePath.register);
                },
                child: Text(
                  "Don't have an account? Sign up",
                  style: TextStyle(
                    color: isDarkMode ? colorScheme.onPrimary : Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
