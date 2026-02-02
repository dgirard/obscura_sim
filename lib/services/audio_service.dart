import 'package:audioplayers/audioplayers.dart';
import 'logger_service.dart';

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
      AppLogger.audio('Error playing shutter: $e');
    }
  }

  Future<void> playDeveloping() async {
    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.release);
      await player.play(AssetSource('sounds/developing.mp3'));
    } catch (e) {
      AppLogger.audio('Error playing developing: $e');
    }
  }
  
  void dispose() {
    // Rien à disposer globalement
  }
}
