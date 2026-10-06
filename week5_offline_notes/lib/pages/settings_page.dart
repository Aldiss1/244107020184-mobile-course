import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/prefs_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkAsync = ref.watch(darkModeProvider);
    final lastOpenedAsync = ref.watch(lastOpenedProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          darkAsync.when(
            loading: () => const ListTile(
              title: Text('Memuat preferensi...'),
              trailing: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Gagal memuat preferensi'),
              subtitle: Text('$e'),
            ),
            data: (isDark) => SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Tema gelap'),
              subtitle: const Text('Disimpan di SharedPreferences'),
              value: isDark,
              onChanged: (_) => ref.read(darkModeProvider.notifier).toggle(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Terakhir dibuka'),
            subtitle: Text(
              lastOpenedAsync.when(
                data: (value) => value ?? 'Baru pertama kali dibuka',
                loading: () => 'Memuat...',
                error: (e, _) => 'Error: $e',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
