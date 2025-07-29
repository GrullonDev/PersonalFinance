import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:personal_finance/features/auth/data/firebase_auth_service.dart';
import 'package:personal_finance/features/profile/domain/profile_repository.dart';
import 'package:personal_finance/features/profile/model/user_profile.dart';
import 'package:personal_finance/utils/injection_container.dart';
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

  final FirebaseAuthService authService = FirebaseAuthService();
  final ProfileRepository profileRepository = getIt<ProfileRepository>();

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

      final String uid = FirebaseAuth.instance.currentUser!.uid;
      await profileRepository.saveProfile(
        UserProfile(
          id: uid,
          firstName: firstNameController.text,
          lastName: lastNameController.text,
          birthDate: DateTime.parse(birthDateController.text),
          username: usernameController.text,
          email: emailController.text,
        ),
      );

      Navigator.pushNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar usuario: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? colorScheme.surface : Colors.grey[50],
        image: isDarkMode 
          ? null 
          : DecorationImage(
              image: const AssetImage('assets/logo.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.white.withValues(alpha: 0.1),
                BlendMode.dstATop,
              ),
            ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Sign Up',
            style: TextStyle(
              color: isDarkMode ? colorScheme.onSurface : Colors.black87,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDarkMode ? colorScheme.onSurface : Colors.black87,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: <Widget>[
                Text(
                  'Your information is safe with us',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? colorScheme.onSurface.withValues(alpha: 0.7) : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: firstNameController,
                  labelText: 'First Name',
                  isDarkMode: isDarkMode,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: lastNameController,
                  labelText: 'Last Name',
                  isDarkMode: isDarkMode,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: birthDateController,
                  labelText: 'Date of Birth',
                  onTap: _selectBirthDate,
                  readOnly: true,
                  isDarkMode: isDarkMode,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: usernameController,
                  labelText: 'Username',
                  isDarkMode: isDarkMode,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: emailController,
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  isDarkMode: isDarkMode,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: confirmEmailController,
                  labelText: 'Confirm Email',
                  keyboardType: TextInputType.emailAddress,
                  isDarkMode: isDarkMode,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: passwordController,
                  labelText: 'Password',
                  obscureText: true,
                  isDarkMode: isDarkMode,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: confirmPasswordController,
                  labelText: 'Confirm Password',
                  obscureText: true,
                  isDarkMode: isDarkMode,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _validateAndRegister,
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
                      'Sign Up', 
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required bool isDarkMode,
    required ColorScheme colorScheme,
    bool obscureText = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onTap: onTap,
      style: TextStyle(
        color: isDarkMode ? colorScheme.onSurface : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: isDarkMode ? colorScheme.onSurface.withValues(alpha: 0.7) : Colors.black54,
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
    );
  }
}
