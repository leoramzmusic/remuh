import 'package:on_audio_query/on_audio_query.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/track.dart';

class LocalAudioSource {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Obtiene los archivos de audio del almacenamiento local
  Future<List<Track>> getAudioFiles() async {
    try {
      // Filtrar para obtener solo música
      List<SongModel> songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      Logger.info('Found ${songs.length} songs');

      return songs.map((song) {
        return Track(
          id: song.id.toString(),
          title: song.title,
          artist: song.artist ?? 'Unknown Artist',
          album: song.album ?? 'Unknown Album',
          duration: Duration(milliseconds: song.duration ?? 0),
          filePath: song.data,
          fileUrl: song.uri,
          artworkPath:
              null, // Artwork needs separate handling with on_audio_query
        );
      }).toList();
    } catch (e) {
      Logger.error('Error fetching local songs: $e');
      return [];
    }
  }
}
