import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:personal_finance/features/auth/domain/auth_repository.dart';
import 'package:personal_finance/features/auth/presentation/bloc/reset_password_bloc.dart';
import 'package:personal_finance/utils/injection_container.dart';

class ResetPasswordPage extends StatelessWidget {
  final String token;

  const ResetPasswordPage({required this.token, super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<ResetPasswordBloc>(
        create: (_) => ResetPasswordBloc(getIt<AuthRepository>()),
        child: _ResetPasswordView(token: token),
      );
}

class _ResetPasswordView extends StatelessWidget {
  final String token;
  const _ResetPasswordView({required this.token});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String newPassword = '';
    String confirmPassword = '';
    return Scaffold(
      appBar: AppBar(title: const Text('Restablecer Contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: BlocConsumer<ResetPasswordBloc, ResetPasswordState>(
          listener: (BuildContext context, ResetPasswordState state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
            }
            if (state.success) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada exitosamente'), backgroundColor: Colors.green));
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> r) => false);
            }
          },
          builder: (BuildContext context, ResetPasswordState state) => Form(
            key: formKey,
            child: ListView(
              children: <Widget>[
                const Text('Crea una nueva contraseña para tu cuenta', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 24),
                TextFormField(
                  obscureText: state.obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(state.obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => context.read<ResetPasswordBloc>().add(ToggleNewObscure()),
                    ),
                  ),
                  onSaved: (String? v) => newPassword = v ?? '',
                  validator: (String? value) {
                    if (value == null || value.isEmpty) return 'Por favor ingresa tu nueva contraseña';
                    if (value.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  obscureText: state.obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(state.obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => context.read<ResetPasswordBloc>().add(ToggleConfirmObscure()),
                    ),
                  ),
                  onSaved: (String? v) => confirmPassword = v ?? '',
                  validator: (String? value) {
                    if (value == null || value.isEmpty) return 'Por favor confirma tu contraseña';
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
                          context.read<ResetPasswordBloc>().add(ResetSubmitted(token: token, newPassword: newPassword, confirmPassword: confirmPassword));
                        },
                  child: state.loading ? const CircularProgressIndicator() : const Text('Restablecer Contraseña'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
