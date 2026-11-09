import 'package:flutter/material.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';

class SleepTimerSheet extends StatelessWidget {
  final MusicProvider provider;

  const SleepTimerSheet({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final options = [
      {'label': 'Matikan Timer', 'minutes': 0},
      {'label': '5 Menit', 'minutes': 5},
      {'label': '15 Menit', 'minutes': 15},
      {'label': '30 Menit', 'minutes': 30},
      {'label': '45 Menit', 'minutes': 45},
      {'label': '1 Jam (60 Menit)', 'minutes': 60},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Pengatur Waktu Tidur 🌙',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Musik akan dijeda secara otomatis setelah durasi waktu habis.',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          ...options.map((opt) {
            final minutes = opt['minutes'] as int;
            final isCurrent = (minutes == 0 && !provider.isSleepTimerActive) ||
                (provider.isSleepTimerActive && (provider.sleepTimerSecondsRemaining / 60).ceil() == minutes);

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                minutes == 0 ? Icons.timer_off_rounded : Icons.timer_rounded,
                color: isCurrent ? AppTheme.accentPink : AppTheme.textMuted,
              ),
              title: Text(
                opt['label'] as String,
                style: TextStyle(
                  color: isCurrent ? AppTheme.accentPink : AppTheme.textPrimary,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              trailing: isCurrent ? const Icon(Icons.check_rounded, color: AppTheme.accentPink) : null,
              onTap: () {
                provider.setSleepTimer(minutes);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
