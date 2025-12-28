import '../entities/track.dart';
import '../repositories/audio_repository.dart';

/// Caso de uso: Cargar una pista
class LoadTrack {
  final AudioRepository repository;

  LoadTrack(this.repository);

  Future<void> call(Track track) async {
    await repository.loadTrack(track);
  }
}
