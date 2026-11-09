import 'package:flutter/material.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';

class EqualizerSheet extends StatelessWidget {
  final MusicProvider provider;

  const EqualizerSheet({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final frequencies = ['60Hz', '230Hz', '910Hz', '3.6k', '14kHz'];

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Studio Suara & Equalizer 🎚️',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => provider.resetEqualizer(),
                child: const Text('Reset', style: TextStyle(color: AppTheme.primaryLight)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Preset Cepat:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SoundProfile.values.map((profile) {
                final isSelected = provider.activeProfile == profile;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(profile.label),
                    selected: isSelected,
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.surfaceLight,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => provider.setSoundProfile(profile),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              final gain = provider.equalizerBands[index];
              return Column(
                children: [
                  Text(
                    (gain > 0 ? '+' : '') + gain.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  ),
                  SizedBox(
                    height: 110,
                    width: 32,
                    child: RotatedBox(
                      quarterTurns: -1,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          activeTrackColor: AppTheme.primary,
                          inactiveTrackColor: AppTheme.surfaceLight,
                          thumbColor: AppTheme.accentPink,
                        ),
                        child: Slider(
                          value: gain,
                          min: -6.0,
                          max: 6.0,
                          onChanged: (val) => provider.setEqualizerBand(index, val),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    frequencies[index],
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
