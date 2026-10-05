import 'package:flutter/material.dart';

import 'Lirik.dart';
import 'Musik.dart';

void main() {
  runApp(const Aldisurya());
}

class Aldisurya extends StatefulWidget {
  const Aldisurya({super.key});

  @override
  State<Aldisurya> createState() => _AldisuryaState();
}

class _AldisuryaState extends State<Aldisurya> {
  late final Musik _laguku;
  int _lirikIndex = 0; // 0: Bagian 1, 1: Bagian 2 (lir)
  bool _isPlaying = false;

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Informasi Musik'),
          centerTitle: true,
          leading: const Icon(Icons.library_music_rounded),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Container 1: Cover Gambar & Info Lagu (Image & ClipRRect)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Widget Image diperbesar dan di tengah
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/image.png',
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _laguku.judul,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_laguku.artis} (${_laguku.tahun})',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Container 2: Lirik Lagu + Navigasi Bait
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _lirikIndex == 0 ? _laguku.lirik.bait1 : _laguku.lirik.bait2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, height: 1.6),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: _lirikIndex > 0
                                ? () {
                                    setState(() => _lirikIndex--);
                                  }
                                : null,
                            icon: const Icon(Icons.skip_previous_rounded),
                            iconSize: 32,
                          ),
                          Text(
                            'Bait ${_lirikIndex + 1}/2',
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          IconButton(
                            onPressed: _lirikIndex < 1
                                ? () {
                                    setState(() => _lirikIndex++);
                                  }
                                : null,
                            icon: const Icon(Icons.skip_next_rounded),
                            iconSize: 32,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Container 3: Tombol Navigasi Kontrol
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isPlaying = !_isPlaying;
                          });
                        },
                        icon: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 20,
                        ),
                        label: Text(_isPlaying ? 'Pause' : 'Play'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isPlaying = false;
                          });
                        },
                        icon: const Icon(Icons.stop_rounded, size: 20),
                        label: const Text('Stop'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
