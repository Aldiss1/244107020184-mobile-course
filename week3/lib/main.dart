import 'package:flutter/material.dart';

import 'Lirik.dart';
import 'Musik.dart';
import 'pages/camera_page.dart';
import 'pages/info_page.dart';
import 'pages/lirik_page.dart';
import 'pages/location_page.dart';
import 'pages/player_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// InheritedWidget – membagikan data lagu & state ke seluruh widget tree
// ─────────────────────────────────────────────────────────────────────────────
class MusicData extends InheritedWidget {
  final Musik musik;
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final VoidCallback onStop;

  const MusicData({
    super.key,
    required this.musik,
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onStop,
    required super.child,
  });

  /// Mengambil MusicData dari context (InheritedWidget.of pattern)
  static MusicData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MusicData>()!;
  }

  @override
  bool updateShouldNotify(MusicData oldWidget) =>
      oldWidget.isPlaying != isPlaying;
}

// ─────────────────────────────────────────────────────────────────────────────
void main() async {
  // Wajib dipanggil sebelum menggunakan plugin seperti camera
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Aldisurya());
}

// StatefulWidget – root app
class Aldisurya extends StatefulWidget {
  const Aldisurya({super.key});

  @override
  State<Aldisurya> createState() => _AldisuryaState();
}

class _AldisuryaState extends State<Aldisurya> {
  late final Musik _laguku;
  bool _isPlaying = false;
  int _selectedIndex = 0;

  // Label & ikon untuk BottomNavigationBar / NavigationRail / Drawer
  static const List<(String label, IconData icon)> _navItems = [
    ('Info', Icons.info_outline_rounded),
    ('Lirik', Icons.lyrics_outlined),
    ('Player', Icons.play_circle_outline_rounded),
    ('Kamera', Icons.camera_alt_outlined),
    ('Lokasi', Icons.location_on_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _laguku = Musik(
      judul: 'Suka Suka',
      artis: 'The Changcuters',
      tahun: 2009,
      lirik: Lirik(),
    );
  }

  void _goTo(int index, BuildContext ctx) {
    setState(() => _selectedIndex = index);
    // Tutup drawer jika sedang terbuka
    if (Navigator.canPop(ctx)) Navigator.pop(ctx);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // ── InheritedWidget membungkus seluruh app ──────────────────────
      home: MusicData(
        musik: _laguku,
        isPlaying: _isPlaying,
        onTogglePlay: () => setState(() => _isPlaying = !_isPlaying),
        onStop: () => setState(() => _isPlaying = false),
        child: Builder(
          builder: (ctx) {
            // Deteksi lebar layar untuk NavigationRail vs BottomNavigationBar
            final isWide = MediaQuery.of(ctx).size.width >= 600;

            return Scaffold(
              // ── AppBar ─────────────────────────────────────────────
              appBar: AppBar(
                title: const Text('Informasi Musik'),
                centerTitle: true,
                leading: Builder(
                  builder: (innerCtx) => IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => Scaffold.of(innerCtx).openDrawer(),
                  ),
                ),
              ),

              // ── Drawer ─────────────────────────────────────────────
              drawer: Drawer(
                child: ListView(
                  children: [
                    const DrawerHeader(
                      child: Text('Menu', style: TextStyle(fontSize: 18)),
                    ),
                    for (int i = 0; i < _navItems.length; i++)
                      ListTile(
                        leading: Icon(_navItems[i].$2),
                        title: Text(_navItems[i].$1),
                        selected: _selectedIndex == i,
                        onTap: () => _goTo(i, ctx),
                      ),
                  ],
                ),
              ),

              // ── Body – NavigationRail (lebar) atau IndexedStack saja ──
              body: Row(
                children: [
                  if (isWide)
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (i) =>
                          setState(() => _selectedIndex = i),
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (final item in _navItems)
                          NavigationRailDestination(
                            icon: Icon(item.$2),
                            label: Text(item.$1),
                          ),
                      ],
                    ),

                  // IndexedStack – menjaga state setiap halaman tetap hidup
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: const [
                        InfoPage(),
                        LirikPage(),
                        PlayerPage(),
                        CameraPage(),
                        LocationPage(),
                      ],
                    ),
                  ),
                ],
              ),

              // ── BottomNavigationBar – hanya di layar sempit ────────
              bottomNavigationBar: isWide
                  ? null
                  : BottomNavigationBar(
                      currentIndex: _selectedIndex,
                      onTap: (i) => setState(() => _selectedIndex = i),
                      items: [
                        for (final item in _navItems)
                          BottomNavigationBarItem(
                            icon: Icon(item.$2),
                            label: item.$1,
                          ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}
