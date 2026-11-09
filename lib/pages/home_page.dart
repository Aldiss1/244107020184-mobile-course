import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../messaging/push_service.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/push_provider.dart';
import '../routes.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final push = ref.watch(pushServiceProvider);
    final profile = ref.watch(userProfileProvider).value;
    final unread = ref.watch(notificationsProvider).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: () => context.push(Routes.notifications),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Debug push',
            onPressed: () => context.push(Routes.debug),
            icon: const Icon(Icons.bug_report_outlined),
          ),
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(profile?.fullName ?? 'Mahasiswa'),
              subtitle: Text(profile?.email ?? 'Profil belum dimuat'),
            ),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<PushSnapshot>(
            valueListenable: push.snapshot,
            builder: (context, snap, _) => _StatusCard(snapshot: snap),
          ),
          const SizedBox(height: 16),
          Text('Uji manual', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Tampilkan notifikasi lokal'),
                  subtitle: const Text(
                    'Mensimulasikan banner foreground: payload '
                    'route=/pengumuman/3',
                  ),
                  onTap: () => push.showLocal(
                    id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
                    title: 'Jadwal kuliah berubah',
                    body: 'Kelas Mobile pindah ke Ruang A2 jam 13.00',
                    route: Routes.announcement('3'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: const Text('Buka pengumuman #3'),
                  subtitle: const Text('Rute tujuan deep link dari notifikasi'),
                  onTap: () => context.push(Routes.announcement('3')),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.tag),
                  title: const Text('Kelola langganan topik'),
                  subtitle: Text(kAnnouncementTopic),
                  onTap: () => _showTopicSheet(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tips pengujian',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const _TipList(),
        ],
      ),
    );
  }

  Future<void> _showTopicSheet(BuildContext context, WidgetRef ref) async {
    final push = ref.read(pushServiceProvider);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_alert_outlined),
              title: const Text('Berlangganan topik'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await push.resubscribeToTopic();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Berlangganan $kAnnouncementTopic'),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined),
              title: const Text('Berhenti berlangganan'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await push.unsubscribeFromTopic();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Berhenti dari $kAnnouncementTopic'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.snapshot});

  final PushSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (snapshot.status) {
      PushStatus.ready => ('FCM siap', Icons.check_circle_outline, Colors.green),
      PushStatus.simulator => (
        'Mode simulator',
        Icons.computer_outlined,
        Colors.indigo,
      ),
      PushStatus.denied => (
        'Izin notifikasi ditolak',
        Icons.do_not_disturb_on_outlined,
        Colors.orange,
      ),
      PushStatus.disabled => (
        'Firebase belum dikonfigurasi',
        Icons.cloud_off_outlined,
        Colors.blueGrey,
      ),
      PushStatus.error => ('Gagal init FCM', Icons.error_outline, Colors.red),
      PushStatus.unknown => (
        'Menyiapkan...',
        Icons.hourglass_empty,
        Colors.blueGrey,
      ),
    };

    final subtitle = switch (snapshot.status) {
      PushStatus.simulator =>
        'Token FCM tidak tersedia di simulator — kirim payload lewat '
            'tool/sim_push.sh',
      _ => snapshot.tokenPreview == null
          ? 'Token belum tersedia'
          : 'Token: ${snapshot.tokenPreview}',
    };

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _TipList extends StatelessWidget {
  const _TipList();

  @override
  Widget build(BuildContext context) {
    const tips = [
      'Foreground: banner tidak muncul otomatis, harus lewat '
          'flutter_local_notifications.',
      'Background: banner sistem muncul, klik ditangani onMessageOpenedApp.',
      'Terminated: klik ditangani getInitialMessage saat aplikasi dibuka.',
      'Token berubah setelah reinstall -> onTokenRefresh wajib mengirim '
          'ulang ke backend.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final tip in tips)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(child: Text(tip)),
              ],
            ),
          ),
      ],
    );
  }
}
