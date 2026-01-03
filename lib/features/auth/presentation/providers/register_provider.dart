import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:personal_finance/features/auth/data/models/request/register_user_request.dart';
import 'package:personal_finance/features/auth/data/models/response/register_user_response.dart';
import 'package:personal_finance/features/auth/domain/auth_failure.dart';
import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';
import 'package:personal_finance/features/profile/domain/profile_repository.dart';
import 'package:personal_finance/features/profile/domain/entities/user_profile.dart';
import 'package:personal_finance/utils/validators.dart';

class RegisterResult {
  RegisterResult._({required this.isSuccess, this.message});

  final bool isSuccess;
  final String? message;

  factory RegisterResult.success() => RegisterResult._(isSuccess: true);

  factory RegisterResult.failure(String message) =>
      RegisterResult._(isSuccess: false, message: message);
}

class RegisterProvider extends ChangeNotifier {
  RegisterProvider({
    required AuthProvider authProvider,
    required ProfileRepository profileRepository,
  }) : _authProvider = authProvider,
       _profileRepository = profileRepository;

  final AuthProvider _authProvider;
  final ProfileRepository _profileRepository;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController confirmEmailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  DateTime? _birthDate;

  DateTime? get birthDate => _birthDate;

  void setBirthDate(DateTime date) {
    _birthDate = date;
    birthDateController.text = _formatDate(date);
    notifyListeners();
  }

  void clearForm() {
    firstNameController.clear();
    lastNameController.clear();
    birthDateController.clear();
    usernameController.clear();
    emailController.clear();
    confirmEmailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    _birthDate = null;
    notifyListeners();
  }

  Future<RegisterResult> submit() async {
    final List<String?> errors = _validateFields();
    final List<String> messages = errors.whereType<String>().toList();

    if (messages.isNotEmpty) {
      return RegisterResult.failure(messages.join('\n'));
    }

    final RegisterUserRequest request = RegisterUserRequest(
      nombres: firstNameController.text,
      apellidos: lastNameController.text,
      fechaNacimiento: birthDateController.text,
      username: usernameController.text,
      email: emailController.text,
      emailConfirmacion: confirmEmailController.text,
      password: passwordController.text,
      passwordConfirmacion: confirmPasswordController.text,
    );

    final Either<AuthFailure, RegisterUserResponse> result = await _authProvider
        .registerUser(request);

    return result.fold<Future<RegisterResult>>(
      (AuthFailure failure) =>
          Future<RegisterResult>.value(RegisterResult.failure(failure.message)),
      (RegisterUserResponse response) =>
          _handleSuccessfulRegistration(response),
    );
  }

  Future<RegisterResult> _handleSuccessfulRegistration(
    RegisterUserResponse response,
  ) async {
    final String uid =
        FirebaseAuth.instance.currentUser?.uid ?? response.firebaseUid;

    await _profileRepository.saveProfile(
      UserProfile(
        id: uid,
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        birthDate: _birthDate ?? DateTime.parse(birthDateController.text),
        username: usernameController.text,
        email: emailController.text,
      ),
    );

    clearForm();
    return RegisterResult.success();
  }

  List<String?> _validateFields() {
    final DateTime? selectedBirthDate =
        _birthDate ?? DateTime.tryParse(birthDateController.text);

    final String? firstNameError = AppValidators.validateRequired(
      firstNameController.text,
      'Nombres',
    );
    final String? lastNameError = AppValidators.validateRequired(
      lastNameController.text,
      'Apellidos',
    );
    final String? birthDateError = AppValidators.validateBirthDate(
      selectedBirthDate,
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

    return <String?>[
      firstNameError,
      lastNameError,
      birthDateError,
      usernameError,
      emailError,
      confirmEmailError,
      passwordError,
      confirmPasswordError,
    ];
  }

  String _formatDate(DateTime date) => date.toLocal().toString().split(' ')[0];

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    birthDateController.dispose();
    usernameController.dispose();
    emailController.dispose();
    confirmEmailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
