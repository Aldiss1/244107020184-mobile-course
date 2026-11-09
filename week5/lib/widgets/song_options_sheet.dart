import 'package:flutter/material.dart';
import '../models/song.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/album_artwork.dart';

class SongOptionsSheet extends StatelessWidget {
  final Song song;
  final MusicProvider provider;

  const SongOptionsSheet({super.key, required this.song, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Row(
            children: [
              AlbumArtwork(song: song, size: 50, borderRadius: 10),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                    ),
                    Text(
                      '${song.artist} • ${song.album}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.queue_play_next_rounded, color: AppTheme.textPrimary),
            title: const Text('Putar Berikutnya', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
            onTap: () {
              provider.playNext(song);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lagu "${song.title}" disetel untuk putar berikutnya')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add_rounded, color: AppTheme.textPrimary),
            title: const Text('Tambahkan ke Antrean', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
            onTap: () {
              provider.addToQueue(song);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lagu "${song.title}" ditambahkan ke antrean')),
              );
            },
          ),
          ListTile(
            leading: Icon(
              song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: song.isFavorite ? AppTheme.accentPink : AppTheme.textPrimary,
            ),
            title: Text(
              song.isFavorite ? 'Hapus dari Favorit' : 'Sukai Lagu',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            ),
            onTap: () {
              provider.toggleFavorite(song);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_to_photos_rounded, color: AppTheme.textPrimary),
            title: const Text('Tambahkan ke Playlist', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              _showAddToPlaylistDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Pilih Playlist', style: TextStyle(color: AppTheme.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: provider.playlists.length,
            itemBuilder: (c, i) {
              final pl = provider.playlists[i];
              return ListTile(
                title: Text(pl.name, style: const TextStyle(color: AppTheme.textPrimary)),
                subtitle: Text('${pl.songs.length} lagu', style: const TextStyle(color: AppTheme.textMuted)),
                onTap: () {
                  provider.addSongToPlaylist(pl, song);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ditambahkan ke ${pl.name}')),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
