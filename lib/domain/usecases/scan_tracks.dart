import '../entities/track.dart';
import '../repositories/audio_repository.dart';

class ScanTracks {
  final AudioRepository _repository;

  ScanTracks(this._repository);

  Future<List<Track>> call() async {
    return await _repository.getDeviceTracks();
  }
}
