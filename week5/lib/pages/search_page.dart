import 'package:flutter/material.dart';
import '../providers/music_provider.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';
import '../widgets/album_artwork.dart';
import '../widgets/song_options_sheet.dart';
import 'now_playing_page.dart';

class SearchPage extends StatefulWidget {
  final MusicProvider provider;

  const SearchPage({super.key, required this.provider});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  final List<Map<String, dynamic>> _genreCategories = [
    {
      'title': 'Indie & Pop',
      'colors': [const Color(0xFF6366F1), const Color(0xFF3B82F6)],
      'icon': Icons.headphones_rounded,
    },
    {
      'title': 'Rock Enerjik',
      'colors': [const Color(0xFFEF4444), const Color(0xFFF97316)],
      'icon': Icons.electric_bolt_rounded,
    },
    {
      'title': 'Ballad Galau',
      'colors': [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
      'icon': Icons.favorite_rounded,
    },
    {
      'title': 'Synthwave & R&B',
      'colors': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      'icon': Icons.nightlife_rounded,
    },
    {
      'title': 'Folk & Akustik',
      'colors': [const Color(0xFF10B981), const Color(0xFF059669)],
      'icon': Icons.spa_rounded,
    },
    {
      'title': 'Podcast & Cerita',
      'colors': [const Color(0xFF06B6D4), const Color(0xFF0284C7)],
      'icon': Icons.mic_rounded,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSongs = widget.provider.allSongs.where((song) {
      final q = _query.toLowerCase();
      return song.title.toLowerCase().contains(q) ||
          song.artist.toLowerCase().contains(q) ||
          song.album.toLowerCase().contains(q) ||
          song.genre.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Eksplor & Cari 🔍'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SEARCH INPUT BOX
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _query = val),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari lagu, artis, lirik, atau genre...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryLight),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_query.isNotEmpty) ...[
              Text(
                'Hasil Pencarian (${filteredSongs.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (filteredSongs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        const Text('Tidak ada lagu yang cocok', style: TextStyle(color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredSongs.length,
                  itemBuilder: (context, index) {
                    final song = filteredSongs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        onTap: () {
                          widget.provider.playSong(song);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NowPlayingPage(provider: widget.provider),
                            ),
                          );
                        },
                        leading: AlbumArtwork(song: song, size: 46, borderRadius: 8),
                        title: Text(
                          song.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                        ),
                        subtitle: Text(
                          '${song.artist} • ${song.genre}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted, size: 20),
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => SongOptionsSheet(song: song, provider: widget.provider),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ] else ...[
              const Text(
                'Jelajahi Berdasarkan Suasana & Genre',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _genreCategories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemBuilder: (context, index) {
                  final cat = _genreCategories[index];
                  return InkWell(
                    onTap: () {
                      _searchController.text = cat['title'].toString().split(' ').first;
                      setState(() => _query = _searchController.text);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: cat['colors'] as List<Color>,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (cat['colors'] as List<Color>).first.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(cat['icon'] as IconData, color: Colors.white, size: 26),
                          Text(
                            cat['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
