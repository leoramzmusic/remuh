import '../entities/track.dart';

/// Estados de reproducción
enum PlaybackState { stopped, playing, paused, buffering, completed, error }

/// Modos de repetición
enum AudioRepeatMode { off, one, all }

/// Repositorio abstracto para operaciones de audio
abstract class AudioRepository {
  /// Inicializar el reproductor
  Future<void> initialize();

  /// Cargar una pista
  Future<void> loadTrack(Track track);

  /// Obtener pistas del dispositivo
  Future<List<Track>> getDeviceTracks();

  /// Reproducir
  Future<void> play();

  /// Pausar
  Future<void> pause();

  /// Detener
  Future<void> stop();

  /// Buscar a una posición específica
  Future<void> seek(Duration position);

  /// Obtener el estado actual
  Stream<PlaybackState> get playbackStateStream;

  /// Obtener la posición actual
  Stream<Duration> get positionStream;

  /// Obtener la duración total
  Stream<Duration?> get durationStream;

  /// Obtener la pista actual
  Track? get currentTrack;

  /// Liberar recursos
  Future<void> dispose();

  /// Cambiar modo de repetición
  Future<void> setRepeatMode(AudioRepeatMode mode);

  /// Activar/desactivar aleatorio
  Future<void> setShuffleMode(bool enabled);

  /// Eliminar permanentemente el archivo de una pista
  Future<bool> deleteTrackFile(Track track);
}
