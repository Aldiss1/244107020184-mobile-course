import 'package:flutter/material.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/album_artwork.dart';
import '../widgets/live_visualizer.dart';
import '../pages/now_playing_page.dart';

class MiniPlayer extends StatelessWidget {
  final MusicProvider provider;

  const MiniPlayer({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final song = provider.currentSong;
    if (song == null) return const SizedBox.shrink();

    final progress = provider.duration.inSeconds > 0
        ? (provider.position.inSeconds / provider.duration.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, anim1, anim2) => NowPlayingPage(provider: provider),
            transitionsBuilder: (context, anim, secondaryAnim, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22).withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mini Live Progress Line
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
                minHeight: 2.5,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    AlbumArtwork(song: song, size: 44, borderRadius: 10),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Text(
                                song.artist,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '• ${provider.activeProfile.label}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.primaryLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    LiveVisualizer(
                      isPlaying: provider.isPlaying,
                      barColor: AppTheme.secondary,
                      barCount: 3,
                      maxHeight: 14,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        provider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => provider.togglePlayPause(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, color: AppTheme.textSecondary, size: 24),
                      onPressed: () => provider.next(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
