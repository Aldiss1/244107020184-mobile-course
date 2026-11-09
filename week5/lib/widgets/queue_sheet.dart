import 'package:flutter/material.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/album_artwork.dart';

class QueueSheet extends StatelessWidget {
  final MusicProvider provider;

  const QueueSheet({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final queue = provider.queue;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Antrean Putar Sekarang 🎶',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.builder(
              itemCount: queue.length,
              itemBuilder: (context, index) {
                final song = queue[index];
                final isCurrent = provider.currentSong?.id == song.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isCurrent ? AppTheme.primary.withOpacity(0.15) : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    onTap: () {
                      provider.playSong(song);
                      Navigator.pop(context);
                    },
                    leading: AlbumArtwork(song: song, size: 40, borderRadius: 8),
                    title: Text(
                      song.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isCurrent ? AppTheme.primaryLight : AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(song.artist, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    trailing: isCurrent
                        ? const Icon(Icons.volume_up_rounded, color: AppTheme.primaryLight)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
