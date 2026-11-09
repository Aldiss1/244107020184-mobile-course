import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/notification_store.dart';
import '../providers/notification_provider.dart';
import '../providers/push_provider.dart';

/// Daftar notifikasi belum dibaca.
///
/// "Dibaca" = item di-tap: aplikasi membuka rute tujuannya dan item
/// langsung hilang dari daftar (serta dari badge).
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'Hapus semua',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClearAll(context, ref),
            ),
        ],
      ),
      body: items.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(item.title),
                  subtitle: Text('${item.body} · ${_jamMenit(item.createdAt)}'),
                  onTap: () => _baca(item, context, ref),
                );
              },
            ),
    );
  }

  Future<void> _baca(
    StoredNotification item,
    BuildContext context,
    WidgetRef ref,
  ) async {
    await ref.read(notificationsProvider.notifier).remove(item.id);
    await ref
        .read(pushServiceProvider)
        .dismissLocal(int.tryParse(item.id) ?? -1);
    if (context.mounted) context.go(item.route);
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus semua?'),
        content: const Text('Semua notifikasi akan dihapus dari daftar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(notificationsProvider.notifier).clearAll();
    }
  }

  String _jamMenit(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    // ListView (bukan Center) supaya tetap bisa di-scroll bila layar pendek,
    // tetapi isinya di tengah secara horizontal — sebelumnya teks menempel
    // ke tepi kiri karena `ListView` merentangkan anaknya selebar layar.
    return ListView(
      children: const [
        SizedBox(height: 120),
        Center(child: Icon(Icons.notifications_none, size: 48)),
        SizedBox(height: 16),
        Center(child: Text('Belum ada notifikasi.')),
      ],
    );
  }
}
