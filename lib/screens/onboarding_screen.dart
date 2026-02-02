import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/settings/settings_bloc.dart';
import '../navigation/app_router.dart';
import '../theme/colors.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ObscuraColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(
                Icons.camera_alt_outlined,
                size: 80,
                color: ObscuraColors.primary,
              ),
              const SizedBox(height: 32),
              const Text(
                'Bienvenue dans Obscura',
                style: TextStyle(
                  color: ObscuraColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Cette application simule l\'expérience authentique d\'une chambre noire ("Camera Obscura").',
                style: TextStyle(
                  color: ObscuraColors.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildFeatureItem(
                Icons.rotate_90_degrees_ccw,
                'Viseur Inversé',
                'Comme dans une vraie chambre noire, l\'image est inversée. C\'est normal ! C\'est de l\'art.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                Icons.hourglass_bottom,
                'Développement',
                'Prenez le temps. Stabilisez votre appareil. La photo apparaît après développement.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<SettingsBloc>().add(CompleteOnboarding());
                    context.go(AppRoutes.camera);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ObscuraColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: ObscuraColors.background,
                  ),
                  child: const Text(
                    'Commencer l\'expérience',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ObscuraColors.textGhost,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: ObscuraColors.primary, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ObscuraColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: ObscuraColors.textTertiary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
