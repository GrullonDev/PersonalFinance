import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
          listener: (BuildContext context, ForgotPasswordState state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!)),
              );
            }
            if (state.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Se ha enviado un correo para restablecer tu contraseña'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop();
            }
          },
          builder: (BuildContext context, ForgotPasswordState state) => Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (String? v) => email = (v ?? '').trim(),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) return 'Por favor ingresa tu correo electrónico';
                    if (!value.contains('@')) return 'Por favor ingresa un correo electrónico válido';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: state.loading
                      ? null
                      : () {
                          if (!formKey.currentState!.validate()) return;
                          formKey.currentState!.save();
                          context.read<ForgotPasswordBloc>().add(ForgotSubmitted(email));
                        },
                  child: state.loading ? const CircularProgressIndicator() : const Text('Enviar Enlace'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Volver al Inicio de Sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

