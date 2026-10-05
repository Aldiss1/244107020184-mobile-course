import 'package:flutter/material.dart';
import '../main.dart';
import 'detail_page.dart';

/// StatelessWidget – Tab Info Lagu.
/// Widget yang diimplementasikan:
///   - StatelessWidget
///   - FutureBuilder + CircularProgressIndicator
///   - Hero + PageRouteBuilder + FadeTransition
///   - Banner
///   - Tooltip + showModalBottomSheet
///   - Tooltip + showDialog (AlertDialog) + SnackBar
class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  // Simulasi async fetch data lagu (FutureBuilder)
  Future<void> _fetchInfo() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final music = MusicData.of(context);

    return FutureBuilder<void>(
      future: _fetchInfo(),
      builder: (ctx, snapshot) {
        // CircularProgressIndicator saat data belum tersedia
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            primary: true,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Hero ─────────────────────────────────────────────────
                // Tap cover → buka DetailPage via PageRouteBuilder + FadeTransition
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 500),
                        pageBuilder: (_, animation, _) => FadeTransition(
                          opacity: animation,
                          child: const DetailPage(),
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'album-art',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/image.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap cover untuk detail',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),

                // ── Banner ───────────────────────────────────────────────
                // Badge "PLAYING" muncul di pojok kanan atas saat lagu diputar
                Banner(
                  message: music.isPlaying ? 'PLAYING' : '   ',
                  location: BannerLocation.topEnd,
                  color: Colors.green,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          music.musik.judul,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${music.musik.artis} (${music.musik.tahun})'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // ── Tooltip + showModalBottomSheet ────────────────────
                    Tooltip(
                      message: 'Lihat detail lagu',
                      child: ElevatedButton(
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          builder: (_) => Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Detail Lagu',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(),
                                Text('Judul  : ${music.musik.judul}'),
                                Text('Artis  : ${music.musik.artis}'),
                                Text('Tahun  : ${music.musik.tahun}'),
                              ],
                            ),
                          ),
                        ),
                        child: const Text('Detail'),
                      ),
                    ),

                    // ── Tooltip + showDialog (AlertDialog) + SnackBar ─────
                    Tooltip(
                      message: 'Hapus lagu dari daftar',
                      child: ElevatedButton(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Konfirmasi'),
                            content: const Text('Hapus lagu ini?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Lagu dihapus'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        ),
                        child: const Text('Hapus'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
