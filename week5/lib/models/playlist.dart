import 'song.dart';

class Playlist {
  final String id;
  String name;
  String description;
  String coverUrl;
  final List<Song> songs;
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    this.description = '',
    required this.coverUrl,
    required this.songs,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get songCount => songs.length;
}
