import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

enum IconStyle { material, cupertino }

class AppIconSet {
  final IconData play;
  final IconData pause;
  final IconData skipNext;
  final IconData skipPrevious;
  final IconData shuffle;
  final IconData repeat;
  final IconData repeatOne;
  final IconData playlist;
  final IconData lyrics;
  final IconData favorite;
  final IconData favoriteBorder;
  final IconData album;
  final IconData artist;
  final IconData queue;
  final IconData settings;
  final IconData search;
  final IconData delete;
  final IconData add;
  final IconData save;

  const AppIconSet({
    required this.play,
    required this.pause,
    required this.skipNext,
    required this.skipPrevious,
    required this.shuffle,
    required this.repeat,
    required this.repeatOne,
    required this.playlist,
    required this.lyrics,
    required this.favorite,
    required this.favoriteBorder,
    required this.album,
    required this.artist,
    required this.queue,
    required this.settings,
    required this.search,
    required this.delete,
    required this.add,
    required this.save,
  });

  static const AppIconSet material = AppIconSet(
    play: Icons.play_arrow_rounded,
    pause: Icons.pause_rounded,
    skipNext: Icons.skip_next_rounded,
    skipPrevious: Icons.skip_previous_rounded,
    shuffle: Icons.shuffle_rounded,
    repeat: Icons.repeat_rounded,
    repeatOne: Icons.repeat_one_rounded,
    playlist: Icons.playlist_play_rounded,
    lyrics: Icons.lyrics_rounded,
    favorite: Icons.favorite_rounded,
    favoriteBorder: Icons.favorite_border_rounded,
    album: Icons.album_rounded,
    artist: Icons.person_rounded,
    queue: Icons.keyboard_arrow_up_rounded,
    settings: Icons.settings_rounded,
    search: Icons.search_rounded,
    delete: Icons.delete_outline_rounded,
    add: Icons.add_rounded,
    save: Icons.save_rounded,
  );

  static const AppIconSet cupertino = AppIconSet(
    play: CupertinoIcons.play_fill,
    pause: CupertinoIcons.pause_fill,
    skipNext: CupertinoIcons.forward_fill,
    skipPrevious: CupertinoIcons.backward_fill,
    shuffle: CupertinoIcons.shuffle,
    repeat: CupertinoIcons.repeat,
    repeatOne: CupertinoIcons.repeat_1,
    playlist: CupertinoIcons.list_bullet,
    lyrics: CupertinoIcons.text_quote,
    favorite: CupertinoIcons.heart_fill,
    favoriteBorder: CupertinoIcons.heart,
    album: CupertinoIcons.music_albums,
    artist: CupertinoIcons.person_fill,
    queue: CupertinoIcons.chevron_up,
    settings: CupertinoIcons.settings,
    search: CupertinoIcons.search,
    delete: CupertinoIcons.trash,
    add: CupertinoIcons.add,
    save: CupertinoIcons.check_mark,
  );

  static AppIconSet fromStyle(IconStyle style) {
    switch (style) {
      case IconStyle.cupertino:
        return cupertino;
      case IconStyle.material:
        return material;
    }
  }
}
