import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings/settings_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Paramètres', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Expérience',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _buildSwitchTile(
                title: 'Viseur Inversé',
                subtitle: 'Simuler l\'optique réelle (rotation 180°)',
                value: state.isInvertedViewfinder,
                onChanged: (value) {
                  context.read<SettingsBloc>().add(ToggleInvertedViewfinder(value));
                },
              ),
              const Divider(color: Colors.white12, height: 32),
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Caméra',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Qualité d\'image',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                subtitle: Text(
                  state.imageQuality == ResolutionPreset.high ? 'Haute' : 'Moyenne',
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
                trailing: DropdownButton<ResolutionPreset>(
                  value: state.imageQuality,
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: ResolutionPreset.medium,
                      child: Text('Moyenne (Rapide)'),
                    ),
                    DropdownMenuItem(
                      value: ResolutionPreset.high,
                      child: Text('Haute (Détails)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      context.read<SettingsBloc>().add(SetImageQuality(value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Redémarrez la caméra pour appliquer'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white60, fontSize: 14),
      ),
      value: value,
      activeColor: Colors.amber,
      onChanged: onChanged,
    );
  }
}
