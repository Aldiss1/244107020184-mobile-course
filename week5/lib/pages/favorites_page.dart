import 'package:flutter/material.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/album_artwork.dart';
import '../widgets/mini_player.dart';
import 'now_playing_page.dart';

class FavoritesPage extends StatelessWidget {
  final MusicProvider provider;

  const FavoritesPage({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final favorites = provider.favoriteSongs;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Lagu yang Disukai ❤️'),
      ),
      body: Stack(
        children: [
          if (favorites.isEmpty)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 64, color: AppTheme.textMuted),
                  SizedBox(height: 16),
                  Text('Belum ada lagu yang disukai', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                  SizedBox(height: 6),
                  Text('Ketuk ikon hati pada lagu untuk menyimpannya di sini', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            )
          else
            ListView.builder(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 120),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final song = favorites[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    onTap: () {
                      provider.playSong(song, customQueue: favorites);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => NowPlayingPage(provider: provider)),
                      );
                    },
                    leading: AlbumArtwork(song: song, size: 48, borderRadius: 10),
                    title: Text(
                      song.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                    ),
                    subtitle: Text(
                      '${song.artist} • ${song.album}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite_rounded, color: AppTheme.accentPink),
                      onPressed: () => provider.toggleFavorite(song),
                    ),
                  ),
                );
              },
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(provider: provider),
          ),
        ],
      ),
    );
  }
}
