import 'package:flutter/material.dart';

import '../routes.dart';

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengumuman')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Chip(
            avatar: const Icon(Icons.link, size: 16),
            label: Text('${Routes.announcementPattern} -> id "$id"'),
          ),
          const SizedBox(height: 16),
          Text(
            'Jadwal kuliah berubah',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Kelas Mobile pindah ke Ruang A2 jam 13.00. '
            'Mohon hadir tepat waktu.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Halaman ini adalah target deep link dari notifikasi. Kalau Anda '
            'tiba di sini setelah menekan banner notifikasi, berarti '
            'routeFromMessage() berhasil membaca data.route pada ketiga '
            'app state.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
