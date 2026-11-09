import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/album_artwork.dart';
import '../widgets/mini_player.dart';
import 'now_playing_page.dart';

class PlaylistDetailPage extends StatelessWidget {
  final Playlist playlist;
  final MusicProvider provider;

  const PlaylistDetailPage({super.key, required this.playlist, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240.0,
                pinned: true,
                backgroundColor: AppTheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    playlist.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF312E81), Color(0xFF1E1B4B), AppTheme.background],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.4),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.library_music_rounded, color: Colors.white, size: 40),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            playlist.description,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (playlist.songs.isNotEmpty) {
                              provider.playSong(playlist.songs.first, customQueue: playlist.songs);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => NowPlayingPage(provider: provider)),
                              );
                            }
                          },
                          icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                          label: const Text('Putar Semua', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (playlist.songs.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('Playlist ini masih kosong', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = playlist.songs[index];
                        final isCurrent = provider.currentSong?.id == song.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isCurrent ? AppTheme.primary.withOpacity(0.12) : AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            onTap: () {
                              provider.playSong(song, customQueue: playlist.songs);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => NowPlayingPage(provider: provider)),
                              );
                            },
                            leading: AlbumArtwork(song: song, size: 44, borderRadius: 8),
                            title: Text(
                              song.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                            ),
                            subtitle: Text(
                              '${song.artist} • ${song.duration}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.textMuted, size: 20),
                              onPressed: () => provider.removeSongFromPlaylist(playlist, song),
                            ),
                          ),
                        );
                      },
                      childCount: playlist.songs.length,
                    ),
                  ),
                ),
            ],
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
