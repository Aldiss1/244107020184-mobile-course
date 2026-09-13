import 'package:flutter/material.dart';

import 'Lirik.dart';
import 'Musik.dart';

void main() {
  runApp(const Aldisurya());
}

class Aldisurya extends StatelessWidget {
  const Aldisurya({super.key});

  @override
  Widget build(BuildContext context) {
    Musik laguku = Musik(
      judul: 'Suka Suka',
      artis: 'The Changcuters',
      tahun: 2009,
      lirik: Lirik(),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Informasi Musik'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Container 1: Info Lagu
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${laguku.judul} - ${laguku.artis} (${laguku.tahun})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Container 2: Lirik Lagu
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  laguku.lirik.bait,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
              ),
              const SizedBox(height: 16),

              // Container 3: button
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
                    ElevatedButton(onPressed: () {}, child: const Text('Back')),
                    ElevatedButton(onPressed: () {}, child: const Text('Play')),
                    ElevatedButton(onPressed: () {}, child: const Text('Stop')),
                    ElevatedButton(onPressed: () {}, child: const Text('Next')),
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
