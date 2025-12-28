import '../../domain/entities/track.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../services/audio_service.dart';
import '../../services/permission_service.dart';
import '../datasources/local_audio_source.dart';

/// Implementación del repositorio de audio
class AudioRepositoryImpl implements AudioRepository {
  final AudioService _audioService;
  final PermissionService _permissionService;
  final LocalAudioSource _localAudioSource;

  AudioRepositoryImpl(
    this._audioService,
    this._permissionService,
    this._localAudioSource,
  );

  @override
  Future<void> initialize() => _audioService.initialize();

  @override
  Future<List<Track>> getDeviceTracks() async {
    final hasPermission = await _permissionService.requestStoragePermission();
    if (hasPermission) {
      return await _localAudioSource.getAudioFiles();
    } else {
      return [];
    }
  }

  @override
  Future<void> loadTrack(Track track) => _audioService.loadTrack(track);

  @override
  Future<void> play() => _audioService.play();

  @override
  Future<void> pause() => _audioService.pause();

  @override
  Future<void> stop() => _audioService.stop();

  @override
  Future<void> seek(Duration position) => _audioService.seek(position);

  @override
  Stream<PlaybackState> get playbackStateStream =>
      _audioService.playbackStateStream;

  @override
  Stream<Duration> get positionStream => _audioService.positionStream;

  @override
  Stream<Duration?> get durationStream => _audioService.durationStream;

  @override
  Track? get currentTrack => _audioService.currentTrack;

  @override
  Future<void> dispose() => _audioService.dispose();
}
