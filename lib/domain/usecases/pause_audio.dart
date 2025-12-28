import '../repositories/audio_repository.dart';

/// Caso de uso: Pausar audio
class PauseAudio {
  final AudioRepository repository;

  PauseAudio(this.repository);

  Future<void> call() async {
    await repository.pause();
  }
}
