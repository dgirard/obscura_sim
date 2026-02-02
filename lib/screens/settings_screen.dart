import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings/settings_bloc.dart';
import '../theme/colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ObscuraColors.background,
      appBar: AppBar(
        backgroundColor: ObscuraColors.background,
        title: const Text('Paramètres', style: TextStyle(color: ObscuraColors.textPrimary)),
        iconTheme: const IconThemeData(color: ObscuraColors.textPrimary),
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
                    color: ObscuraColors.primary,
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
              const Divider(color: ObscuraColors.textFaint, height: 32),
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Caméra',
                  style: TextStyle(
                    color: ObscuraColors.primary,
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
                  style: TextStyle(color: ObscuraColors.textPrimary, fontSize: 16),
                ),
                subtitle: Text(
                  state.imageQuality == ResolutionPreset.high ? 'Haute' : 'Moyenne',
                  style: const TextStyle(color: ObscuraColors.textTertiary, fontSize: 14),
                ),
                trailing: DropdownButton<ResolutionPreset>(
                  value: state.imageQuality,
                  dropdownColor: ObscuraColors.surface,
                  style: const TextStyle(color: ObscuraColors.textPrimary),
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
        style: const TextStyle(color: ObscuraColors.textPrimary, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: ObscuraColors.textTertiary, fontSize: 14),
      ),
      value: value,
      activeTrackColor: ObscuraColors.primary.withValues(alpha: 0.5),
      activeThumbColor: ObscuraColors.primary,
      onChanged: onChanged,
    );
  }
}
