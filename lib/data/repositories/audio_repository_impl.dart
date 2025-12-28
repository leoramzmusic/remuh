import 'dart:io';
import 'package:audio_service/audio_service.dart' as as_lib;
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../services/audio_service.dart';
import '../../services/permission_service.dart';
import '../datasources/local_audio_source.dart';

/// Implementación del repositorio de audio
class AudioRepositoryImpl implements AudioRepository {
  final AudioPlayerHandler _audioHandler;
  final PermissionService _permissionService;
  final LocalAudioSource _localAudioSource;

  AudioRepositoryImpl(
    this._audioHandler,
    this._permissionService,
    this._localAudioSource,
  );

  @override
  Future<void> initialize() async {
    // Initialization is handled by AudioService.init in main.dart
  }

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
  Future<void> loadTrack(Track track) async {
    // Intentar obtener la carátula antes de pasarla al handler (Isolate Principal)
    Track trackWithArtwork = track;
    try {
      final bytes = await _localAudioSource.getArtwork(int.parse(track.id));
      if (bytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/artwork_${track.id}.jpg');
        await file.writeAsBytes(bytes);
        trackWithArtwork = track.copyWith(artworkPath: file.uri.toString());
      }
    } catch (e) {
      // Ignorar error de carátula, seguir adelante
    }

    return _audioHandler.loadTrack(trackWithArtwork);
  }

  @override
  Future<void> play() => _audioHandler.play();

  @override
  Future<void> pause() => _audioHandler.pause();

  @override
  Future<void> stop() => _audioHandler.stop();

  @override
  Future<void> seek(Duration position) => _audioHandler.seek(position);

  @override
  Stream<PlaybackState> get playbackStateStream =>
      _audioHandler.playbackState.map((state) {
        final processingState = state.processingState;
        if (processingState == as_lib.AudioProcessingState.idle) {
          return PlaybackState.stopped;
        }
        if (processingState == as_lib.AudioProcessingState.loading ||
            processingState == as_lib.AudioProcessingState.buffering) {
          return PlaybackState.buffering;
        }
        if (processingState == as_lib.AudioProcessingState.completed) {
          return PlaybackState.completed;
        }
        if (state.playing) {
          return PlaybackState.playing;
        }
        return PlaybackState.paused;
      });

  @override
  Stream<Duration> get positionStream => as_lib.AudioService.position;

  @override
  Stream<Duration?> get durationStream =>
      _audioHandler.mediaItem.map((item) => item?.duration);

  @override
  Track? get currentTrack {
    final item = _audioHandler.mediaItem.value;
    if (item == null) return null;
    return Track(
      id: item.id,
      title: item.title,
      artist: item.artist,
      album: item.album,
      duration: item.duration ?? Duration.zero,
      fileUrl: item.extras?['url'] as String?,
      filePath: item.extras?['path'] as String? ?? '',
      artworkPath: item.artUri?.toString(),
    );
  }

  @override
  Future<void> dispose() => _audioHandler.stop();
}
