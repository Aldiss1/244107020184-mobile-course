import 'package:flutter/material.dart';

class LyricLine {
  final double timestampSeconds;
  final String text;

  LyricLine({required this.timestampSeconds, required this.text});
}

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String duration;
  final double durationSeconds;
  final String coverUrl;
  final String audioUrl;
  final String genre;
  final List<Color> gradientColors;
  final IconData genreIcon;
  final List<LyricLine> syncedLyrics;
  bool isFavorite;
  int playCount;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.durationSeconds,
    required this.coverUrl,
    required this.audioUrl,
    required this.genre,
    required this.gradientColors,
    required this.genreIcon,
    required this.syncedLyrics,
    this.isFavorite = false,
    this.playCount = 0,
  });

  String get fullLyrics => syncedLyrics.map((l) => l.text).join("\n");
}
