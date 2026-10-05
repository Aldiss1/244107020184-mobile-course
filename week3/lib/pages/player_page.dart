import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';

/// StatefulWidget – Tab Player.
/// Widget yang diimplementasikan:
///   - StatefulWidget
///   - ScaleTransition + FadeTransition
///   - ValueListenableBuilder
///   - LinearProgressIndicator
///   - StreamBuilder
///   - CircularProgressIndicator (loading awal stream)
///   - AnimatedContainer
///   - SnackBar
class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with SingleTickerProviderStateMixin {
  // AnimationController untuk ScaleTransition & FadeTransition
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  // ValueNotifier untuk LinearProgressIndicator + ValueListenableBuilder
  final ValueNotifier<double> _progress = ValueNotifier(0.0);

  // StreamController untuk StreamBuilder
  StreamController<double>? _streamCtrl;
  Timer? _timer;
  bool _wasPlaying = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _fadeAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  // Membuat stream baru yang mengalirkan nilai progress setiap 300ms
  Stream<double> _makeProgressStream() {
    _streamCtrl?.close();
    _streamCtrl = StreamController<double>.broadcast();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (_streamCtrl == null || _streamCtrl!.isClosed) {
        t.cancel();
        return;
      }
      double next = _progress.value + 0.005;
      if (next >= 1.0) next = 0.0;
      _progress.value = next;
      _streamCtrl!.add(next);
    });

    return _streamCtrl!.stream;
  }

  void _stopStream() {
    _timer?.cancel();
    _timer = null;
    _streamCtrl?.close();
    _streamCtrl = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isPlaying = MusicData.of(context).isPlaying;

    if (isPlaying && !_wasPlaying) {
      // Baru mulai play → mulai stream
      _makeProgressStream();
    } else if (!isPlaying && _wasPlaying) {
      // Stop → hentikan stream & reset
      _stopStream();
      _progress.value = 0.0;
    }
    _wasPlaying = isPlaying;
  }

  @override
  void dispose() {
    _stopStream();
    _ctrl.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final music = MusicData.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── ScaleTransition + FadeTransition ─────────────────────────
          // Cover album berdenyut saat lagu diputar
          ScaleTransition(
            scale: music.isPlaying
                ? _scaleAnim
                : const AlwaysStoppedAnimation(1.0),
            child: FadeTransition(
              opacity: music.isPlaying
                  ? _fadeAnim
                  : const AlwaysStoppedAnimation(1.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/image.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── ValueListenableBuilder – teks progress ────────────────────
          ValueListenableBuilder<double>(
            valueListenable: _progress,
            builder: (_, value, _) => Text(
              'Progress: ${(value * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),

          // ── LinearProgressIndicator ───────────────────────────────────
          ValueListenableBuilder<double>(
            valueListenable: _progress,
            builder: (_, value, _) => LinearProgressIndicator(value: value),
          ),
          const SizedBox(height: 20),

          // ── StreamBuilder ─────────────────────────────────────────────
          // Menampilkan status putar secara real-time dari stream
          StreamBuilder<double>(
            stream: _streamCtrl?.stream,
            builder: (_, snap) {
              if (!music.isPlaying) {
                return const Text('Tekan Play untuk memulai');
              }
              // CircularProgressIndicator saat menunggu data pertama dari stream
              if (!snap.hasData) {
                return const CircularProgressIndicator();
              }
              return Text(
                'Sedang diputar... ${(snap.data! * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.blue),
              );
            },
          ),
          const SizedBox(height: 24),

          // ── AnimatedContainer – tombol play/stop ──────────────────────
          // Ukuran, warna, dan border-radius berubah animasi saat state berubah
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            width: music.isPlaying ? 180 : 130,
            height: 52,
            decoration: BoxDecoration(
              color: music.isPlaying
                  ? Colors.blue.shade700
                  : Colors.grey.shade300,
              borderRadius:
                  BorderRadius.circular(music.isPlaying ? 26 : 8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Tombol Play / Pause
                IconButton(
                  onPressed: () {
                    final wasPlaying = music.isPlaying;
                    music.onTogglePlay();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(wasPlaying ? 'Dijeda' : 'Diputar'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: Icon(
                    music.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color:
                        music.isPlaying ? Colors.white : Colors.black87,
                  ),
                ),
                // Tombol Stop
                IconButton(
                  onPressed: () {
                    music.onStop();
                  },
                  icon: Icon(
                    Icons.stop_rounded,
                    color:
                        music.isPlaying ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
