import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';
import '../providers/push_provider.dart';

/// Halaman bukti untuk laporan: token ditampilkan **terpotong**.
///
/// Token penuh tidak pernah ditampilkan di layar maupun ditulis ke log, karena
/// screenshot laporan ikut tersimpan di repository publik.
class DebugPage extends ConsumerWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final push = ref.watch(pushServiceProvider);
    final boot = ref.watch(firebaseBootProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Debug push')),
      body: ValueListenableBuilder<PushSnapshot>(
        valueListenable: push.snapshot,
        builder: (context, snap, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Row(label: 'Firebase siap', value: boot.ready ? 'ya' : 'tidak'),
            if (boot.error != null)
              _Row(label: 'Error Firebase', value: boot.error!, mono: true),
            _Row(label: 'Sumber push', value: _sourceLabel(snap.source)),
            _Row(label: 'Status push', value: snap.status.name),
            _Row(
              label: 'Izin notifikasi',
              value: snap.permissionGranted ? 'diberikan' : 'belum',
            ),
            _Row(label: 'Topik', value: snap.topic),
            _Row(
              label: 'Token (terpotong)',
              value: snap.tokenPreview ?? 'belum tersedia',
              mono: true,
            ),
            if (snap.message != null)
              _Row(label: 'Catatan', value: snap.message!, mono: true),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: () => push.showLocal(
                id: 1,
                title: 'Uji notifikasi lokal',
                body: 'Payload route=/pengumuman/3',
                route: '/pengumuman/3',
              ),
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Tampilkan notifikasi lokal'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Token dihapus dari secure storage. Anda diarahkan '
                        'ke /login oleh redirect GoRouter.',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Hapus token & logout'),
            ),
            const SizedBox(height: 24),
            Text(
              'Checklist pengujian',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Foreground: kirim payload, banner lokal muncul, klik -> '
              '/pengumuman/3.\n'
              '2. Background: tekan Home, kirim, klik banner -> '
              '/pengumuman/3.\n'
              '3. Terminated: tutup aplikasi, kirim, klik banner -> '
              '/pengumuman/3 lewat getInitialMessage/getInitialPayload.\n\n'
              'Perintah: ./tool/sim_push.sh foreground|background|terminated',
            ),
          ],
        ),
      ),
    );
  }

  static String _sourceLabel(PushSource source) => switch (source) {
    PushSource.firebase => 'Firebase Cloud Messaging',
    PushSource.bridge => 'Jembatan native iOS (simulator)',
    PushSource.none => 'tidak ada',
    PushSource.unknown => 'belum ditentukan',
  };
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: mono
                ? const TextStyle(fontFamily: 'monospace', fontSize: 13)
                : Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
