import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isTappingAvatar = false;
  ProfileInfo? _initialInfo;

  String _selectedCountryCode = '+504';
  final List<String> _centralAmericanCodes = [
    '+501',
    '+502',
    '+503',
    '+504',
    '+505',
    '+506',
    '+507',
  ];

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
    _initialInfo = context.read<ProfileBloc>().state.info;

    // Intelligent name detection for social login (Google/Apple) users
    String initialFirstName = _initialInfo?.firstName ?? '';
    String initialLastName = _initialInfo?.lastName ?? '';

    // If firstName/lastName are empty but fullName exists
    if (initialFirstName.isEmpty &&
        initialLastName.isEmpty &&
        _initialInfo?.fullName != null &&
        _initialInfo!.fullName.isNotEmpty) {
      final names = _initialInfo!.fullName.trim().split(' ');
      if (names.isNotEmpty) {
        initialFirstName = names[0];
        if (names.length > 1) {
          // Everything after the first word is considered last name
          initialLastName = names.sublist(1).join(' ');
        }
      }
    }

    _firstNameController = TextEditingController(text: initialFirstName);
    _lastNameController = TextEditingController(text: initialLastName);
    _usernameController = TextEditingController(
      text: _initialInfo?.username ?? '',
    );
    _emailController = TextEditingController(text: _initialInfo?.email ?? '');

    // Parse phone number to extract country code
    String initialPhone = _initialInfo?.phoneNumber ?? '';
    for (final code in _centralAmericanCodes) {
      if (initialPhone.startsWith(code)) {
        _selectedCountryCode = code;
        initialPhone = initialPhone.substring(code.length).trim();
        break;
      }
    }

    _phoneController = TextEditingController(text: initialPhone);
    _addressController = TextEditingController(
      text: _initialInfo?.address ?? '',
    );
    _photoUrl = _initialInfo?.photoUrl;

    // Listen for changes to enable/disable save button
    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _usernameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasChanges {
    final String currentFullPhone =
        _phoneController.text.trim().isEmpty
            ? ''
            : '$_selectedCountryCode ${_phoneController.text.trim()}';
    final String initialFullPhone = _initialInfo?.phoneNumber ?? '';

    final bool textChanged =
        _firstNameController.text.trim() !=
            (initialFirstNameFromFull() ?? '') ||
        _lastNameController.text.trim() != (initialLastNameFromFull() ?? '') ||
        _usernameController.text.trim() != (_initialInfo?.username ?? '') ||
        currentFullPhone != initialFullPhone ||
        _addressController.text.trim() != (_initialInfo?.address ?? '');
    final bool photoChanged = _photoUrl != _initialInfo?.photoUrl;
    return textChanged || photoChanged;
  }

  String? initialFirstNameFromFull() {
    if (_initialInfo?.firstName != null &&
        _initialInfo!.firstName!.isNotEmpty) {
      return _initialInfo!.firstName;
    }
    if (_initialInfo?.fullName != null) {
      return _initialInfo!.fullName.split(' ').first;
    }
    return null;
  }

  String? initialLastNameFromFull() {
    if (_initialInfo?.lastName != null && _initialInfo!.lastName!.isNotEmpty) {
      return _initialInfo!.lastName;
    }
    if (_initialInfo?.fullName != null) {
      final names = _initialInfo!.fullName.split(' ');
      if (names.length > 1) return names.sublist(1).join(' ');
    }
    return null;
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Editar Perfil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: _buildStickySaveButton(primaryColor),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  // Avatar con efecto premium
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTapDown:
                              (_) => setState(() => _isTappingAvatar = true),
                          onTapUp:
                              (_) => setState(() => _isTappingAvatar = false),
                          onTapCancel:
                              () => setState(() => _isTappingAvatar = false),
                          onTap: _showEmojiPicker,
                          child: AnimatedScale(
                            scale: _isTappingAvatar ? 0.95 : 1.0,
                            duration: const Duration(milliseconds: 100),
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                                gradient: LinearGradient(
                                  colors: [
                                    primaryColor,
                                    primaryColor.withValues(alpha: 0.5),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              padding: const EdgeInsets.all(3),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child:
                                      _photoUrl != null && _photoUrl!.isNotEmpty
                                          ? (_photoUrl!.contains('://')
                                              ? Image.network(
                                                _photoUrl!,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return _buildDefaultAvatar();
                                                },
                                                errorBuilder:
                                                    (_, __, ___) =>
                                                        _buildDefaultAvatar(),
                                              )
                                              : Center(
                                                child: Text(
                                                  _photoUrl!,
                                                  style: const TextStyle(
                                                    fontSize: 50,
                                                  ),
                                                ),
                                              ))
                                          : _buildDefaultAvatar(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _showEmojiPicker,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(
                            '👉 Cambiar foto de perfil',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildFields(),

                  const SizedBox(height: 24),

                  _buildSecuritySection(primaryColor),

                  const SizedBox(height: 48),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Tus datos están protegidos y cifrados.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Divider(
          thickness: 1,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        ),
      ],
    ),
  );

  InputDecoration _buildInputDecoration({
    required String label,
    IconData? icon,
    Widget? prefixWidget,
    String? hintText,
    String? helperText,
    bool enabled = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      helperText: helperText,
      prefixIcon:
          prefixWidget ??
          (icon != null
              ? Icon(icon, color: enabled ? colorScheme.primary : Colors.grey)
              : null),
      filled: true,
      fillColor: colorScheme.surface,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: TextStyle(
        color: enabled ? colorScheme.primary : Colors.grey,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _buildSecuritySection(Color primaryColor) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionHeader('Seguridad'),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_reset, color: primaryColor, size: 20),
              ),
              title: const Text(
                'Resetear Contraseña',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Enviaremos un correo de recuperación',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: _resetPassword,
            ),
            Divider(
              height: 1,
              indent: 60,
              color: Colors.grey.withValues(alpha: 0.1),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fingerprint,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              title: const Text(
                'Biometría (Próximamente)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Activa FaceID o Huella dactilar',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Switch.adaptive(value: false, onChanged: null),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionHeader('Información Personal'),
      TextFormField(
        controller: _firstNameController,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: _buildInputDecoration(
          label: 'Nombre',
          hintText: 'Tu nombre',
          icon: Icons.person_outline,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'El nombre es requerido';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _lastNameController,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: _buildInputDecoration(
          label: 'Apellido',
          hintText: 'Tu apellido',
          icon: Icons.person_outline,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'El apellido es requerido';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _usernameController,
        decoration: _buildInputDecoration(
          label: 'Usuario',
          hintText: '@nombreusuario',
          icon: Icons.alternate_email,
        ),
      ),
      _buildSectionHeader('Contacto'),
      TextFormField(
        controller: _emailController,
        enabled: false,
        decoration: _buildInputDecoration(
          label: 'Correo electrónico',
          icon: Icons.lock_outline,
          enabled: false,
          helperText: '🔒 Para cambiar tu correo, ve a Seguridad',
        ),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _phoneController,
        decoration: _buildInputDecoration(
          label: 'Teléfono',
          hintText: '0000-0000',
          prefixWidget: Container(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phone_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedCountryCode,
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCountryCode = newValue;
                      });
                      _onFieldChanged();
                    }
                  },
                  items:
                      _centralAmericanCodes.map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.grey.withValues(alpha: 0.2),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ],
            ),
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
        ],
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _addressController,
        decoration: _buildInputDecoration(
          label: 'Dirección',
          hintText: 'Calle, ciudad, país',
          icon: Icons.location_on_outlined,
        ),
        maxLines: 2,
      ),
    ],
  );

  Widget _buildStickySaveButton(Color primaryColor) => Container(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          offset: const Offset(0, -5),
          blurRadius: 10,
        ),
      ],
    ),
    child: SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _hasChanges && !_isLoading ? 1.0 : 0.6,
            child: FilledButton(
              onPressed: _hasChanges && !_isLoading ? _saveProfile : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child:
                  _isLoading
                      ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Guardando...'),
                        ],
                      )
                      : const Text(
                        'Guardar Cambios',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ),
      ),
    ),
  );

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
    // Priority 1: Current data in controllers
    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();

    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      if (firstName.isEmpty) return lastName[0].toUpperCase();
      if (lastName.isEmpty) return firstName[0].toUpperCase();
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }

    // Priority 2: Fallback to fullName from initial info
    if (_initialInfo?.fullName != null && _initialInfo!.fullName.isNotEmpty) {
      final names = _initialInfo!.fullName.trim().split(' ');
      if (names.isNotEmpty) {
        if (names.length > 1) {
          return '${names[0][0]}${names[1][0]}'.toUpperCase();
        }
        return names[0][0].toUpperCase();
      }
    }

    return '?';
  }

  void _showEmojiPicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                          _onFieldChanged();
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                _photoUrl == emoji
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withValues(alpha: 0.1)
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
                    _onFieldChanged();
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
          ),
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
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    await HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final String phone =
          _phoneController.text.trim().isEmpty
              ? ''
              : '$_selectedCountryCode ${_phoneController.text.trim()}';

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
        phoneNumber: phone.isEmpty ? null : phone,
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
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Perfil actualizado correctamente'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
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
