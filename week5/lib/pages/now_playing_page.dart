import 'dart:math';
import 'package:flutter/material.dart';
import '../providers/music_provider.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';
import '../widgets/album_artwork.dart';
import '../widgets/live_visualizer.dart';
import '../widgets/equalizer_sheet.dart';
import '../widgets/queue_sheet.dart';
import '../widgets/sleep_timer_sheet.dart';

class NowPlayingPage extends StatefulWidget {
  final MusicProvider provider;

  const NowPlayingPage({super.key, required this.provider});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> with SingleTickerProviderStateMixin {
  late AnimationController _vinylController;
  bool _showLyricsMode = false;
  final ScrollController _lyricsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    if (widget.provider.isPlaying) {
      _vinylController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant NowPlayingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.provider.isPlaying && !_vinylController.isAnimating) {
      _vinylController.repeat();
    } else if (!widget.provider.isPlaying && _vinylController.isAnimating) {
      _vinylController.stop();
    }
  }

  @override
  void dispose() {
    _vinylController.dispose();
    _lyricsScrollController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.provider.currentSong;
    if (song == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: Text('Tidak ada lagu yang sedang diputar')),
      );
    }

    final activeLyricIdx = widget.provider.currentLyricIndex;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Dynamic Ambient Ambient Gradient Backdrop
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  song.gradientColors.first.withOpacity(0.4),
                  const Color(0xFF131127),
                  AppTheme.background,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30, color: AppTheme.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Column(
                        children: [
                          const Text(
                            'MEMUTAR DARI KOLEKSI',
                            style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            song.album,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.bedtime_outlined, color: AppTheme.textPrimary, size: 22),
                        tooltip: 'Sleep Timer',
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => SleepTimerSheet(provider: widget.provider),
                        ),
                      ),
                    ],
                  ),
                ),

                // MODE TOGGLE CHIP (Vinyl View vs Synced Karaoke Lyrics)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModeTab('🎵 Artwork', !_showLyricsMode, () => setState(() => _showLyricsMode = false)),
                        _buildModeTab('🎤 Karaoke Lirik', _showLyricsMode, () => setState(() => _showLyricsMode = true)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Center Dynamic Content (Artwork or Synced Lyrics)
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showLyricsMode
                        ? _buildKaraokeLyricsView(song, activeLyricIdx)
                        : _buildVinylArtworkView(song),
                  ),
                ),

                const SizedBox(height: 10),

                // Track Title & Favorite Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.artist,
                              style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: song.isFavorite ? AppTheme.accentPink : AppTheme.textSecondary,
                          size: 28,
                        ),
                        onPressed: () => widget.provider.toggleFavorite(song),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Progress Bar & Duration Indicators
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.primaryLight,
                          inactiveTrackColor: Colors.white.withOpacity(0.12),
                          thumbColor: Colors.white,
                          overlayColor: AppTheme.primary.withOpacity(0.3),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: widget.provider.position.inSeconds.toDouble().clamp(0.0, song.durationSeconds),
                          min: 0.0,
                          max: song.durationSeconds,
                          onChanged: (val) {
                            widget.provider.seek(Duration(seconds: val.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(widget.provider.position),
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            Text(
                              song.duration,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Playback Controls (Shuffle, Prev, Play/Pause, Next, Repeat)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: widget.provider.isShuffle ? AppTheme.primaryLight : AppTheme.textMuted,
                          size: 24,
                        ),
                        onPressed: () => widget.provider.toggleShuffle(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, size: 36, color: AppTheme.textPrimary),
                        onPressed: () => widget.provider.previous(),
                      ),
                      GestureDetector(
                        onTap: () {
                          widget.provider.togglePlayPause();
                          if (widget.provider.isPlaying) {
                            _vinylController.repeat();
                          } else {
                            _vinylController.stop();
                          }
                        },
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.45),
                                blurRadius: 18,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.provider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 38,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 36, color: AppTheme.textPrimary),
                        onPressed: () => widget.provider.next(),
                      ),
                      IconButton(
                        icon: Icon(
                          widget.provider.repeatState == RepeatState.one
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded,
                          color: widget.provider.repeatState != RepeatState.off ? AppTheme.primaryLight : AppTheme.textMuted,
                          size: 24,
                        ),
                        onPressed: () => widget.provider.toggleRepeat(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Bottom Utilities Row (Equalizer Studio, Audio Visualizer, Queue List)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => EqualizerSheet(provider: widget.provider),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.graphic_eq_rounded, size: 16, color: AppTheme.secondary),
                              const SizedBox(width: 6),
                              Text(
                                widget.provider.activeProfile.label,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      LiveVisualizer(
                        isPlaying: widget.provider.isPlaying,
                        barColor: AppTheme.secondary,
                        barCount: 5,
                        maxHeight: 18,
                      ),
                      IconButton(
                        icon: const Icon(Icons.queue_music_rounded, color: AppTheme.textSecondary, size: 24),
                        tooltip: 'Antrean Lagu',
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => QueueSheet(provider: widget.provider),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildVinylArtworkView(Song song) {
    return Center(
      child: AnimatedBuilder(
        animation: _vinylController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _vinylController.value * 2 * pi,
            child: AlbumArtwork(
              song: song,
              size: 260,
              showVinylEffect: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildKaraokeLyricsView(Song song, int activeIdx) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ListView.builder(
        controller: _lyricsScrollController,
        itemCount: song.syncedLyrics.length,
        itemBuilder: (context, index) {
          final line = song.syncedLyrics[index];
          final isActive = index == activeIdx;

          return InkWell(
            onTap: () {
              widget.provider.seek(Duration(seconds: line.timestampSeconds.toInt()));
            },
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary.withOpacity(0.25) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isActive ? Border.all(color: AppTheme.primaryLight.withOpacity(0.4)) : null,
              ),
              child: Row(
                children: [
                  if (isActive)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.mic_external_on_rounded, color: AppTheme.secondary, size: 16),
                    ),
                  Expanded(
                    child: Text(
                      line.text,
                      style: TextStyle(
                        fontSize: isActive ? 16 : 14,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? Colors.white : AppTheme.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
