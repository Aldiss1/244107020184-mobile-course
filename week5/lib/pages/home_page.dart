import 'package:flutter/material.dart';
import '../providers/music_provider.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';
import '../widgets/album_artwork.dart';
import '../widgets/live_visualizer.dart';
import '../widgets/song_options_sheet.dart';
import '../widgets/sleep_timer_sheet.dart';
import 'now_playing_page.dart';

class HomePage extends StatefulWidget {
  final MusicProvider provider;

  const HomePage({super.key, required this.provider});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedMood = 'Semua';
  final List<String> _moods = ['Semua', '⚡ Energy Rock', '☕ Lo-Fi Santai', '💔 Ballad Galau', '✨ Synthwave', '🌿 Folk'];

  List<Song> _getFilteredSongs() {
    if (_selectedMood == 'Semua') return widget.provider.allSongs;
    if (_selectedMood.contains('Rock')) return widget.provider.allSongs.where((s) => s.genre.contains('Rock')).toList();
    if (_selectedMood.contains('Lo-Fi') || _selectedMood.contains('Santai')) return widget.provider.allSongs.where((s) => s.genre.contains('Pop') || s.genre.contains('Akustik')).toList();
    if (_selectedMood.contains('Ballad')) return widget.provider.allSongs.where((s) => s.genre.contains('Ballad')).toList();
    if (_selectedMood.contains('Synthwave')) return widget.provider.allSongs.where((s) => s.genre.contains('Synth') || s.genre.contains('R&B')).toList();
    if (_selectedMood.contains('Folk')) return widget.provider.allSongs.where((s) => s.genre.contains('Folk')).toList();
    return widget.provider.allSongs;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi ☀️';
    if (hour < 15) return 'Selamat Siang 🌤️';
    if (hour < 18) return 'Selamat Sore 🌇';
    return 'Selamat Malam 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final songs = _getFilteredSongs();
    final featuredSong = widget.provider.currentSong ?? widget.provider.allSongs.first;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // 1. SLEEK APP BAR WITH AMBIENT ACTIONS
          SliverAppBar(
            backgroundColor: AppTheme.background.withOpacity(0.85),
            floating: true,
            pinned: false,
            elevation: 0,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Text(
                  'Putar lagu favoritmu dengan kualitas Hi-Fi',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],),
            actions: [
              if (widget.provider.isSleepTimerActive)
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => SleepTimerSheet(provider: widget.provider),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPink.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accentPink.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_rounded, size: 14, color: AppTheme.accentPink),
                        const SizedBox(width: 4),
                        Text(
                          '${(widget.provider.sleepTimerSecondsRemaining / 60).ceil()}m',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentPink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.bedtime_outlined, color: AppTheme.textPrimary),
                tooltip: 'Pengatur Waktu Tidur',
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => SleepTimerSheet(provider: widget.provider),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // 2. MAIN BODY CONTENT
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // MOOD CHIPS (Neo Glass Pills)
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _moods.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final mood = _moods[index];
                        final isSelected = mood == _selectedMood;
                        return InkWell(
                          onTap: () => setState(() => _selectedMood = mood),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppTheme.primaryGradient : null,
                              color: isSelected ? null : AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.08),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primary.withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              mood,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // FEATURED HERO DISC CARD (Distinct Apple Music / Cyber Luxe style)
                  _buildFeaturedHeroCard(context, featuredSong),

                  const SizedBox(height: 28),

                  // SECTION: TRENDING & VIBES CAROUSEL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pilihan Populer 🔥',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        '${widget.provider.allSongs.length} Lagu',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildTrendingCarousel(context),

                  const SizedBox(height: 28),

                  // SECTION: ALL SONGS LIST
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedMood == 'Semua' ? 'Daftar Lagu Terbaru' : 'Kategori: $_selectedMood',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // 3. SONG LIST SLIVER
          SliverPadding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = songs[index];
                  final isCurrent = widget.provider.currentSong?.id == song.id;
                  final isPlaying = isCurrent && widget.provider.isPlaying;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppTheme.primary.withOpacity(0.12) : AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrent ? AppTheme.primary.withOpacity(0.4) : Colors.white.withOpacity(0.04),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onTap: () {
                        widget.provider.playSong(song, customQueue: songs);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NowPlayingPage(provider: widget.provider),
                          ),
                        );
                      },
                      leading: Stack(
                        alignment: Alignment.center,
                        children: [
                          AlbumArtwork(song: song, size: 50, borderRadius: 10),
                          if (isCurrent)
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: LiveVisualizer(
                                  isPlaying: isPlaying,
                                  barColor: AppTheme.secondary,
                                  barCount: 3,
                                  maxHeight: 18,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        song.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isCurrent ? AppTheme.primaryLight : AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              song.genre,
                              style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${song.artist} • ${song.duration}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: song.isFavorite ? AppTheme.accentPink : AppTheme.textMuted,
                              size: 20,
                            ),
                            onPressed: () => widget.provider.toggleFavorite(song),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted, size: 20),
                            onPressed: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => SongOptionsSheet(song: song, provider: widget.provider),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: songs.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedHeroCard(BuildContext context, Song song) {
    final isCurrent = widget.provider.currentSong?.id == song.id;
    final isPlaying = isCurrent && widget.provider.isPlaying;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            song.gradientColors.first.withOpacity(0.85),
            const Color(0xFF1E1B4B),
            const Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: song.gradientColors.first.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentAmber, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      isCurrent ? 'SEDANG DIPUTAR' : 'REKOMENDASI HARI INI',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              LiveVisualizer(isPlaying: isPlaying, barColor: Colors.white, barCount: 4, maxHeight: 16),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              AlbumArtwork(song: song, size: 85, borderRadius: 16, showVinylEffect: true),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${song.artist} • ${song.album}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.75),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            if (isCurrent) {
                              widget.provider.togglePlayPause();
                            } else {
                              widget.provider.playSong(song);
                            }
                          },
                          icon: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 20,
                          ),
                          label: Text(
                            isPlaying ? 'Jeda' : 'Putar Sekarang',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NowPlayingPage(provider: widget.provider),
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_full_rounded, color: Colors.white, size: 20),
                          tooltip: 'Buka Pemutar Penuh',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCarousel(BuildContext context) {
    return SizedBox(
      height: 195,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.provider.allSongs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final song = widget.provider.allSongs[index];
          final isCurrent = widget.provider.currentSong?.id == song.id;

          return InkWell(
            onTap: () {
              widget.provider.playSong(song);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NowPlayingPage(provider: widget.provider),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrent ? AppTheme.primaryLight : Colors.white.withOpacity(0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AlbumArtwork(song: song, size: 116, borderRadius: 12),
                  const SizedBox(height: 10),
                  Text(
                    song.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
