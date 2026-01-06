import 'package:on_audio_query/on_audio_query.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/track.dart';

class LocalAudioSource {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Obtiene los archivos de audio del almacenamiento local
  Future<List<Track>> getAudioFiles() async {
    try {
      final queryId = DateTime.now().millisecondsSinceEpoch % 10000;
      Logger.info('[$queryId] Requesting local songs from system...');
      // Filtrar para obtener solo música
      // We add a timeout because on_audio_query can sometimes hang on certain devices
      List<SongModel> songs = await _audioQuery
          .querySongs(
            sortType: SongSortType.TITLE,
            orderType: OrderType.ASC_OR_SMALLER,
            uriType: UriType.EXTERNAL,
            ignoreCase: true,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              Logger.error('[$queryId] Audio query timed out after 10 seconds');
              return [];
            },
          );

      Logger.info('[$queryId] Found ${songs.length} songs');

      return songs.map((song) {
        return Track(
          id: song.id.toString(),
          title: song.title,
          artist: song.artist ?? 'Unknown Artist',
          album: song.album ?? 'Unknown Album',
          genre: song.genre,
          duration: Duration(milliseconds: song.duration ?? 0),
          filePath: song.data,
          fileUrl: song.uri,
          artworkPath: null,
          year: int.tryParse(song.getMap['year']?.toString() ?? ''),
          dateAdded: song.dateAdded != null
              ? DateTime.fromMillisecondsSinceEpoch(song.dateAdded! * 1000)
              : null,
        );
      }).toList();
    } catch (e) {
      Logger.error('Error fetching local songs: $e');
      return [];
    }
  }

  /// Obtiene los bytes de la carátula de una canción
  Future<List<int>?> getArtwork(int id) async {
    try {
      return await _audioQuery.queryArtwork(
        id,
        ArtworkType.AUDIO,
        size: 1000, // Máxima resolución razonable
        format: ArtworkFormat.JPEG,
        quality: 100,
      );
    } catch (e) {
      Logger.error('Error fetching artwork bytes: $e');
      return null;
    }
  }
}
