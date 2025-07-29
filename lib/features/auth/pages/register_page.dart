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
    final String? usernameError = AppValidators.validateUsername(
      usernameController.text,
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
    final String? passwordError = AppValidators.validatePassword(
      passwordController.text,
    );
    final String? confirmPasswordError = AppValidators.validatePasswordConfirmation(
      passwordController.text,
      confirmPasswordController.text,
    );

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

    // Verificar si el username ya existe
    try {
      final bool usernameExists = await authService.isUsernameExists(usernameController.text);
      if (usernameExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El nombre de usuario ya está en uso')),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al verificar nombre de usuario: ${e.toString()}')),
      );
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
        image:
            isDarkMode
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
                    color:
                        isDarkMode
                            ? colorScheme.onSurface.withValues(alpha: 0.7)
                            : Colors.black54,
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
                _buildPasswordField(
                  controller: passwordController,
                  labelText: 'Password',
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
  }) => TextField(
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
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: isDarkMode ? colorScheme.surface : Colors.white,
      ),
    );

  /// Widget especializado para el campo de contraseña con indicadores visuales
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required bool isDarkMode,
    required ColorScheme colorScheme,
  }) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        final String password = controller.text;
        final bool hasMinLength = password.length >= 8;
        final bool hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
        final bool hasNumber = RegExp(r'[0-9]').hasMatch(password);
        final bool hasLowercase = RegExp(r'[a-z]').hasMatch(password);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: controller,
              obscureText: true,
              onChanged: (String value) => setState(() {}),
              style: TextStyle(
                color: isDarkMode ? colorScheme.onSurface : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: labelText,
                labelStyle: TextStyle(
                  color: isDarkMode
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
            if (password.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? colorScheme.surface.withValues(alpha: 0.8)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode ? colorScheme.outline : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Requisitos de contraseña:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? colorScheme.onSurface : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPasswordRequirement(
                      'Al menos 8 caracteres',
                      hasMinLength,
                      isDarkMode,
                      colorScheme,
                    ),
                    _buildPasswordRequirement(
                      'Al menos una mayúscula',
                      hasUppercase,
                      isDarkMode,
                      colorScheme,
                    ),
                    _buildPasswordRequirement(
                      'Al menos un número',
                      hasNumber,
                      isDarkMode,
                      colorScheme,
                    ),
                    _buildPasswordRequirement(
                      'Al menos una minúscula',
                      hasLowercase,
                      isDarkMode,
                      colorScheme,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Widget para mostrar cada requisito de contraseña
  Widget _buildPasswordRequirement(
    String text,
    bool isValid,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: <Widget>[
          Icon(
            isValid ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isValid
                ? Colors.green
                : (isDarkMode ? colorScheme.onSurface.withValues(alpha: 0.5) : Colors.grey),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isValid
                  ? Colors.green
                  : (isDarkMode ? colorScheme.onSurface.withValues(alpha: 0.7) : Colors.grey[600]),
              fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
