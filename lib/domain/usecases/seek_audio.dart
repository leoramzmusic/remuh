import '../repositories/audio_repository.dart';

/// Caso de uso: Buscar a una posición en el audio
class SeekAudio {
  final AudioRepository repository;

  SeekAudio(this.repository);

  Future<void> call(Duration position) async {
    await repository.seek(position);
  }
}
