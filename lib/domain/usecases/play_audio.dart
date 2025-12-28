import '../repositories/audio_repository.dart';

/// Caso de uso: Reproducir audio
class PlayAudio {
  final AudioRepository repository;

  PlayAudio(this.repository);

  Future<void> call() async {
    await repository.play();
  }
}
