import 'package:flutter/material.dart';

import 'package:personal_finance/features/auth/data/firebase_auth_service.dart';
import 'package:personal_finance/utils/validators.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController confirmEmailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  final FirebaseAuthService authService = FirebaseAuthService();

  Future<void> _selectBirthDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        birthDateController.text =
            pickedDate.toLocal().toString().split(' ')[0];
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      isPasswordVisible = !isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      isConfirmPasswordVisible = !isConfirmPasswordVisible;
    });
  }

  Future<void> _validateAndRegister() async {
    final String? firstNameError = AppValidators.validateRequired(
      firstNameController.text,
      'Nombres',
    );
    final String? lastNameError = AppValidators.validateRequired(
      lastNameController.text,
      'Apellidos',
    );
    final String? birthDateError = AppValidators.validateBirthDate(
      DateTime.tryParse(birthDateController.text),
      'Fecha de Nacimiento',
    );
    final String? usernameError = AppValidators.validateRequired(
      usernameController.text,
      'Usuario',
    );
    final String? emailError =
        AppValidators.validateRequired(
          emailController.text,
          'Correo Electrónico',
        ) ??
        AppValidators.validateEmail(emailController.text);
    final String? confirmEmailError =
        emailController.text != confirmEmailController.text
            ? 'Los correos no coinciden'
            : null;
    final String? passwordError = AppValidators.validateRequired(
      passwordController.text,
      'Contraseña',
    );
    final String? confirmPasswordError =
        passwordController.text != confirmPasswordController.text
            ? 'Las contraseñas no coinciden'
            : null;

    final List<String?> errors = <String?>[
      firstNameError,
      lastNameError,
      birthDateError,
      usernameError,
      emailError,
      confirmEmailError,
      passwordError,
      confirmPasswordError,
    ];

    if (errors.any((String? error) => error != null)) {
      final String errorMessage = errors
          .where((String? error) => error != null)
          .join('\n');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    // Proceed with registration logic
    try {
      await authService.registerUser(
        emailController.text,
        passwordController.text,
      );
      Navigator.pushNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar usuario: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Registro')),
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'Nombres'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Apellidos'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: birthDateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Fecha de Nacimiento',
              ),
              onTap: _selectBirthDate,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Usuario'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: confirmEmailController,
              decoration: const InputDecoration(
                labelText: 'Confirmar Correo Electrónico',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: !isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: confirmPasswordController,
              obscureText: !isConfirmPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Confirmar Contraseña',
                suffixIcon: IconButton(
                  icon: Icon(
                    isConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: _toggleConfirmPasswordVisibility,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _validateAndRegister,
              child: const Text('Registrarse'),
            ),
          ],
        ),
      ),
    ),
  );
}
