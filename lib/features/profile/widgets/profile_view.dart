import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:personal_finance/features/profile/logic/profile_logic.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final ProfileLogic logic = context.read<ProfileLogic>();
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet<void>(
      context: context,
      builder:
          (BuildContext context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Usar cámara'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? file = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (file != null) {
                    await logic.uploadPhoto(File(file.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de galería'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? file = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (file != null) {
                    await logic.uploadPhoto(File(file.path));
                  }
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProfileLogic logic = context.watch<ProfileLogic>();

    if (logic.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (logic.error != null) {
      return Center(child: Text(logic.error!));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => _pickImage(context),
            child: Stack(
              children: <Widget>[
                CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      logic.photoUrl != null
                          ? NetworkImage(logic.photoUrl!)
                          : null,
                  child:
                      logic.photoUrl == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Nombre'),
                    subtitle: Text(logic.name ?? 'No disponible'),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                      // TODO: Implementar edición de nombre
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email'),
                    subtitle: Text(logic.email ?? 'No disponible'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Configuración'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Implementar navegación a configuración
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Ayuda'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Implementar navegación a ayuda
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.exit_to_app),
                  title: const Text('Cerrar sesión'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => logic.signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
