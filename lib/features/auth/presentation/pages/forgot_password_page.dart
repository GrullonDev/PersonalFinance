import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:personal_finance/core/presentation/widgets/custom_text_field.dart';
import 'package:personal_finance/core/presentation/widgets/glass_container.dart';
import 'package:personal_finance/core/presentation/widgets/premium_background.dart';
import 'package:personal_finance/features/auth/domain/auth_repository.dart';
import 'package:personal_finance/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:personal_finance/utils/injection_container.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<ForgotPasswordBloc>(
    create: (_) => ForgotPasswordBloc(getIt<AuthRepository>()),
    child: const _ForgotPasswordView(),
  );
}

class _ForgotPasswordView extends StatelessWidget {
  const _ForgotPasswordView();

  @override
  Widget build(BuildContext context) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String email = '';
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Recuperar Contraseña',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              child: GlassContainer(
                padding: const EdgeInsets.all(24),
                child: BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
                  listener: (BuildContext context, ForgotPasswordState state) {
                    if (state.error != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(state.error!)));
                    }
                    if (state.success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Se ha enviado un correo para restablecer tu contraseña',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  builder:
                      (BuildContext context, ForgotPasswordState state) => Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.lock_reset,
                              size: 80,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            CustomTextField(
                              label: 'Correo Electrónico',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              onSaved: (String? v) => email = (v ?? '').trim(),
                              validator: (String? value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu correo electrónico';
                                }
                                if (!value.contains('@')) {
                                  return 'Por favor ingresa un correo electrónico válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    state.loading
                                        ? null
                                        : () {
                                          if (!formKey.currentState!
                                              .validate()) {
                                            return;
                                          }
                                          formKey.currentState!.save();
                                          context
                                              .read<ForgotPasswordBloc>()
                                              .add(ForgotSubmitted(email));
                                        },
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
                                    state.loading
                                        ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : const Text(
                                          'Enviar Enlace',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Volver al Inicio de Sesión',
                                style: TextStyle(color: Colors.white70),
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
      ),
    );
  }
}
