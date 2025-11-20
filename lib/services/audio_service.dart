import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playShutter() async {
    try {
      // Ensure the mode is correct for playback
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(AssetSource('sounds/shutter.mp3'));
    } catch (e) {
      // Silent failure if asset missing or audio issue
      print('Audio error: $e');
    }
  }

  Future<void> playDeveloping() async {
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(AssetSource('sounds/developing.mp3'));
    } catch (e) {
      print('Audio error: $e');
    }
  }
  
  void dispose() {
    _player.dispose();
  }
}
