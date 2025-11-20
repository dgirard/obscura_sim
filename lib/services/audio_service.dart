import 'package:audioplayers/audioplayers.dart';

class AudioService {
  // On crée une nouvelle instance pour chaque son pour éviter les conflits d'état
  // et permettre la superposition des sons si nécessaire.

  Future<void> playShutter() async {
    try {
      final player = AudioPlayer();
      // ReleaseMode.release dispose le player une fois fini
      await player.setReleaseMode(ReleaseMode.release);
      await player.play(AssetSource('sounds/shutter.mp3'));
    } catch (e) {
      print('Audio error (shutter): $e');
    }
  }

  Future<void> playDeveloping() async {
    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.release);
      await player.play(AssetSource('sounds/developing.mp3'));
    } catch (e) {
      print('Audio error (developing): $e');
    }
  }
  
  void dispose() {
    // Rien à disposer globalement
  }
}
