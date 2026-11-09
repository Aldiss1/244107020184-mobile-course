import 'package:flutter/material.dart';
import '../main.dart';

/// StatefulWidget – Tab Lirik.
/// Widget yang diimplementasikan:
///   - StatefulWidget + StatelessWidget (_LyricTab)
///   - TabBar & TabBarView
///   - AnimatedOpacity
///   - AnimatedSwitcher
class LirikPage extends StatefulWidget {
  const LirikPage({super.key});

  @override
  State<LirikPage> createState() => _LirikPageState();
}

class _LirikPageState extends State<LirikPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChange);
  }

  void _onTabChange() {
    if (!_tabController.indexIsChanging) return;
    // AnimatedOpacity: fade out → fade in saat ganti tab
    setState(() => _visible = false);
    Future.delayed(
      const Duration(milliseconds: 250),
      () {
        if (mounted) setState(() => _visible = true);
      },
    );
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final music = MusicData.of(context);

    return Column(
      children: [
        // ── TabBar ───────────────────────────────────────────────────────
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bait 1'),
            Tab(text: 'Bait 2'),
          ],
        ),

        // ── TabBarView ───────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _LyricTab(
                visible: _visible,
                text: music.musik.lirik.bait1,
                valueKey: 'bait1',
              ),
              _LyricTab(
                visible: _visible,
                text: music.musik.lirik.bait2,
                valueKey: 'bait2',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// StatelessWidget – Konten satu tab lirik.
/// Mengimplementasikan AnimatedOpacity + AnimatedSwitcher.
class _LyricTab extends StatelessWidget {
  final bool visible;
  final String text;
  final String valueKey;

  const _LyricTab({
    required this.visible,
    required this.text,
    required this.valueKey,
  });

  @override
  Widget build(BuildContext context) {
    // AnimatedOpacity: transparansi berubah saat ganti tab
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: // AnimatedSwitcher: transisi saat konten berubah
              AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              text,
              key: ValueKey(valueKey),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ),
        ),
      ),
    );
  }
}
