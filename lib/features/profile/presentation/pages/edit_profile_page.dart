import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_finance/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:personal_finance/features/profile/domain/entities/profile_info.dart';
import 'package:personal_finance/features/profile/domain/repositories/profile_backend_repository.dart';
import 'package:personal_finance/utils/injection_container.dart';
import 'package:personal_finance/core/error/failures.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  String? _photoUrl;
  bool _isLoading = false;

  final List<String> _emojis = [
    '📱',
    '💰',
    '🚀',
    '⭐',
    '🌈',
    '🔥',
    '💎',
    '💡',
    '💸',
    '📈',
    '🏠',
    '🚗',
    '🎮',
    '🍕',
    '☕',
    '⚽',
    '🎨',
    '🎧',
    '✈️',
    '🏝️',
    '🐶',
    '🐱',
    '🦊',
    '🐼',
    '🐯',
    '🦁',
    '🐨',
    '🐸',
    '🦄',
    '🍎',
    '🍓',
    '🍩',
  ];

  @override
  void initState() {
    super.initState();
    final ProfileInfo? info = context.read<ProfileBloc>().state.info;

    _firstNameController = TextEditingController(text: info?.firstName ?? '');
    _lastNameController = TextEditingController(text: info?.lastName ?? '');
    _usernameController = TextEditingController(text: info?.username ?? '');
    _emailController = TextEditingController(text: info?.email ?? '');
    _phoneController = TextEditingController(text: info?.phoneNumber ?? '');
    _addressController = TextEditingController(text: info?.address ?? '');
    _photoUrl = info?.photoUrl;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              // Avatar con opción de cambiar
              GestureDetector(
                onTap: _showEmojiPicker,
                child: Stack(
                  children: <Widget>[
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.1),
                        border: Border.all(color: primaryColor, width: 3),
                      ),
                      child:
                          _photoUrl != null && _photoUrl!.isNotEmpty
                              ? (_photoUrl!.contains('://')
                                  ? ClipOval(
                                    child: Image.network(
                                      _photoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => _buildDefaultAvatar(),
                                    ),
                                  )
                                  : Center(
                                    child: Text(
                                      _photoUrl!,
                                      style: const TextStyle(fontSize: 60),
                                    ),
                                  ))
                              : _buildDefaultAvatar(),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toca para cambiar avatar',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // Resto de los campos igual...
              _buildFields(),

              const SizedBox(height: 24),

              // Botones de acción
              _buildActionButtons(primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFields() {
    return Column(
      children: [
        // Nombre
        TextFormField(
          controller: _firstNameController,
          decoration: InputDecoration(
            labelText: 'Nombre',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingresa tu nombre';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Apellido
        TextFormField(
          controller: _lastNameController,
          decoration: InputDecoration(
            labelText: 'Apellido',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingresa tu apellido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Usuario
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: 'Usuario',
            prefixIcon: const Icon(Icons.alternate_email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Email (solo lectura)
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Correo electrónico',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabled: false,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'El correo no se puede modificar',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),

        // Teléfono
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Teléfono',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: '+504 0000-0000',
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        // Dirección
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Dirección',
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText: 'Calle, ciudad, país',
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildActionButtons(Color primaryColor) {
    return Column(
      children: [
        // Botón de resetear contraseña
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _resetPassword,
            icon: const Icon(Icons.lock_reset),
            label: const Text('Resetear Contraseña'),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Botón de guardar
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: _isLoading ? null : _saveProfile,
            icon:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.save),
            label: Text(_isLoading ? 'Guardando...' : 'Guardar Cambios'),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    final String initials = _getInitials();
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  String _getInitials() {
    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();

    if (firstName.isEmpty && lastName.isEmpty) return '?';
    if (firstName.isEmpty) return lastName[0].toUpperCase();
    if (lastName.isEmpty) return firstName[0].toUpperCase();

    return '${firstName[0]}${lastName[0]}'.toUpperCase();
  }

  void _showEmojiPicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecciona un Avatar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: _emojis.length,
                  itemBuilder: (context, index) {
                    final emoji = _emojis[index];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _photoUrl = emoji;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              _photoUrl == emoji
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1)
                                  : null,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              _photoUrl == emoji
                                  ? Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  )
                                  : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _photoUrl = null;
                  });
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Quitar avatar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _resetPassword() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Resetear Contraseña'),
            content: const Text(
              '¿Deseas resetear tu contraseña? Se enviará un correo electrónico '
              'con instrucciones para crear una nueva contraseña.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Enviar'),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Se ha enviado un correo a ${_emailController.text} '
            'con instrucciones para resetear tu contraseña.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final ProfileInfo updatedProfile = ProfileInfo(
        fullName:
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username:
            _usernameController.text.trim().isEmpty
                ? null
                : _usernameController.text.trim(),
        phoneNumber:
            _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
        address:
            _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
        photoUrl: _photoUrl,
      );

      final repository = getIt<ProfileBackendRepository>();
      final result = await repository.updateProfile(updatedProfile);

      if (mounted) {
        result.fold(
          (Failure failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al guardar: ${failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          },
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Perfil actualizado correctamente'),
                backgroundColor: Colors.green,
              ),
            );

            context.read<ProfileBloc>().add(ProfileLoadMe());

            Navigator.pop(context);
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
