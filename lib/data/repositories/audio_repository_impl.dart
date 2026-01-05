import 'dart:io';
import 'package:audio_service/audio_service.dart' as as_lib;

import '../../domain/entities/track.dart';
import '../../domain/entities/scan_progress.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../services/audio_service.dart';
import '../../services/permission_service.dart';
import '../../core/utils/logger.dart';
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

  List<Track>? _cachedTracks;

  @override
  Future<List<Track>> getDeviceTracks() async {
    // Si acabamos de escanear con el stream, devolvemos el caché
    if (_cachedTracks != null) {
      final results = _cachedTracks!;
      // Importante: No limpiamos el caché aquí porque scanLibrary lo llama justo después
      return results;
    }

    Logger.info('AudioRepository: Requesting storage permission...');
    final hasPermission = await _permissionService.requestStoragePermission();

    Logger.info(
      'AudioRepository: Storage permissiongranted: $hasPermission. Requesting notification permission...',
    );
    await _permissionService.requestNotificationPermission();

    if (hasPermission) {
      Logger.info('AudioRepository: Fetching files from LocalAudioSource...');
      _cachedTracks = await _localAudioSource.getAudioFiles();
      return _cachedTracks!;
    } else {
      Logger.warning(
        'AudioRepository: No storage permission, returning empty list',
      );
      return [];
    }
  }

  String _getEmotionalMessage(double percentage) {
    if (percentage < 20) return 'Calentando motores...';
    if (percentage < 40) return 'Buscando tus joyas musicales...';
    if (percentage < 60) return 'Organizando el ritmo...';
    if (percentage < 80) return 'Ya casi tenemos todo listo...';
    return 'Dando los últimos toques...';
  }

  @override
  Stream<ScanProgress> scanDeviceTracks() async* {
    Logger.info('AudioRepository: Starting scan with progress...');

    yield ScanProgress(
      processed: 0,
      total: 0,
      percentage: 0,
      statusMessage: 'Iniciando sistema...',
    );

    final hasPermission = await _permissionService.requestStoragePermission();
    await _permissionService.requestNotificationPermission();

    if (!hasPermission) {
      Logger.warning('AudioRepository: No permission to scan');
      yield ScanProgress(
        processed: 0,
        total: 0,
        percentage: 0,
        statusMessage: 'Acceso denegado. Revisa tus permisos.',
      );
      return;
    }

    yield ScanProgress(
      processed: 0,
      total: 0,
      percentage: 0,
      statusMessage: 'Explorando tus archivos...',
    );

    try {
      // Limpiar caché anterior
      _cachedTracks = null;

      final tracks = await _localAudioSource.getAudioFiles();
      final total = tracks.length;
      _cachedTracks = tracks;

      if (total == 0) {
        yield ScanProgress(
          processed: 0,
          total: 0,
          percentage: 100,
          statusMessage: 'No encontramos música. ¿Está oculta?',
        );
        return;
      }

      yield ScanProgress(
        processed: 0,
        total: total,
        percentage: 0,
        statusMessage: '¡Encontramos $total canciones!',
      );
      await Future.delayed(const Duration(milliseconds: 500));

      final int batchSize = total > 1000 ? 50 : 10;

      for (int i = 0; i < total; i++) {
        final processed = i + 1;

        if (i % batchSize == 0 || i == total - 1) {
          final percentage = (processed / total) * 100;
          yield ScanProgress(
            processed: processed,
            total: total,
            percentage: percentage,
            currentItem: tracks[i].title,
            statusMessage: _getEmotionalMessage(percentage),
          );

          await Future.delayed(const Duration(milliseconds: 1));
        }
      }

      yield ScanProgress(
        processed: total,
        total: total,
        percentage: 100,
        statusMessage: '¡Listo! Tu música te espera.',
      );
    } catch (e) {
      Logger.error('Error during scanDeviceTracks: $e');
      yield ScanProgress(
        processed: 0,
        total: 0,
        percentage: 0,
        statusMessage: 'Vaya, algo salió mal al leer los archivos.',
      );
    }
  }

  /// Prepara un track con su carátula temporal para la notificación
  Future<Track> _prepareTrackWithArtwork(Track track) async {
    try {
      int? trackId = int.tryParse(track.id);
      if (trackId != null) {
        final artworkBytes = await _localAudioSource.getArtwork(trackId);
        if (artworkBytes != null) {
          final tempDir = Directory.systemTemp;
          final artFile = File(
            '${tempDir.path}/notification_art_${track.id}.jpg',
          );
          await artFile.writeAsBytes(artworkBytes);
          return track.copyWith(artworkPath: artFile.uri.toString());
        }
      }
    } catch (e) {
      Logger.error('Error preparing artwork for ${track.title}', e);
    }
    return track;
  }

  @override
  Future<void> loadTrack(Track track) async {
    final trackWithArt = await _prepareTrackWithArtwork(track);
    return _audioHandler.loadTrack(trackWithArt);
  }

  @override
  Future<void> updateQueue(List<Track> tracks, {int initialIndex = 0}) async {
    final List<as_lib.MediaItem> items = [];
    for (final track in tracks) {
      // Optimizamos: para la cola no cargamos todas las imágenes a disco de golpe
      // just_audio las cargará bajo demanda si usamos portadas por defecto o las inyectamos luego.
      // Pero para consistencia mínima usamos la metadata básica.
      items.add(
        as_lib.MediaItem(
          id: track.id,
          album: track.album ?? '',
          title: track.title,
          artist: track.artist ?? '',
          duration: track.duration,
          // artUri dejamos que se cargue dinámicamente o cuando sea la pista activa
          extras: {'url': track.fileUrl, 'path': track.filePath},
        ),
      );
    }
    await _audioHandler.updateQueue(items, initialIndex: initialIndex);
  }

  @override
  Stream<int> get indexChangeStream => _audioHandler.indexChangeStream;

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
  Stream<Duration> get positionStream => _audioHandler.positionStream;

  @override
  Stream<Duration?> get durationStream => _audioHandler.durationStream;

  @override
  Track? get currentTrack {
    final item = _audioHandler.mediaItem.value;
    if (item == null) return null;
    return _mapMediaItemToTrack(item);
  }

  @override
  Stream<Track?> get currentTrackStream => _audioHandler.mediaItem.map((item) {
    if (item == null) return null;
    return _mapMediaItemToTrack(item);
  });

  Track _mapMediaItemToTrack(as_lib.MediaItem item) {
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

  @override
  Future<void> setRepeatMode(AudioRepeatMode mode) =>
      _audioHandler.setRepeatModeCustom(mode);

  @override
  Future<void> setShuffleMode(bool enabled) =>
      _audioHandler.setShuffleModeEnabled(enabled);

  @override
  Stream<bool> get skipRequestStream => _audioHandler.skipRequestStream;

  @override
  Future<bool> deleteTrackFile(Track track) async {
    try {
      final file = File(track.filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
