import 'package:flutter/material.dart';
import 'package:personal_finance/core/presentation/widgets/custom_text_field.dart';
import 'package:personal_finance/core/presentation/widgets/glass_container.dart';
import 'package:personal_finance/core/presentation/widgets/premium_background.dart';
import 'package:personal_finance/features/auth/presentation/providers/auth_provider.dart';
import 'package:personal_finance/features/auth/presentation/providers/register_provider.dart';
import 'package:provider/provider.dart';

class RegisterLayout extends StatelessWidget {
  const RegisterLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final RegisterProvider registerProvider = context.watch<RegisterProvider>();
    final bool isLoading = context.watch<AuthProvider>().isLoading;

    Future<void> handleSelectBirthDate() async {
      FocusScope.of(context).unfocus();
      final DateTime initialDate = registerProvider.birthDate ?? DateTime.now();
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        builder:
            (BuildContext context, Widget? child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.dark(
                  primary: Colors.blue.shade400,
                  onPrimary: Colors.white,
                  surface: const Color(0xFF1E293B),
                  onSurface: Colors.white,
                ),
                dialogBackgroundColor: const Color(0xFF0F172A),
              ),
              child: child!,
            ),
      );
      if (pickedDate != null) {
        registerProvider.setBirthDate(pickedDate);
      }
    }

    Future<void> handleSubmit() async {
      FocusScope.of(context).unfocus();
      final RegisterResult result = await registerProvider.submit();
      if (!context.mounted) {
        return;
      }
      if (result.isSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Registro exitoso')));
        Navigator.pushNamed(context, '/login');
      } else if (result.message?.isNotEmpty ?? false) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message!)));
      }
    }

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Crear Cuenta',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
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
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: <Widget>[
                      const Text(
                        'Tu información está segura con nosotros',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: registerProvider.firstNameController,
                        label: 'Nombre',
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: registerProvider.lastNameController,
                        label: 'Apellido',
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: registerProvider.birthDateController,
                        label: 'Fecha de Nacimiento',
                        readOnly: true,
                        prefixIcon: Icons.calendar_today_outlined,
                        onTap: handleSelectBirthDate,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: registerProvider.usernameController,
                        label: 'Nombre de Usuario',
                        prefixIcon: Icons.alternate_email,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: registerProvider.emailController,
                        label: 'Correo Electrónico',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: registerProvider.confirmEmailController,
                        label: 'Confirmar Correo',
                        prefixIcon: Icons.mark_email_read_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: registerProvider.passwordController,
                        label: 'Contraseña',
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: registerProvider.confirmPasswordController,
                        label: 'Confirmar Contraseña',
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                            shadowColor: Colors.blue.withOpacity(0.5),
                          ),
                          child:
                              isLoading
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    'Registrarse',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
