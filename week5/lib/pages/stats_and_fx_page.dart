import 'package:flutter/material.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/album_artwork.dart';

class StatsAndFxPage extends StatelessWidget {
  final MusicProvider provider;

  const StatsAndFxPage({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Studio FX & Wawasan 🎛️'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: () => provider.resetEqualizer(),
            tooltip: 'Reset EQ',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. STATS BANNER
            _buildListeningStatsCard(context),
            const SizedBox(height: 24),

            // 2. SOUND PROFILES (Slowed, Nightcore, Bass Boost, etc.)
            const Text(
              'Preset Suasana & Karakter Suara',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            _buildSoundProfilesGrid(context),
            const SizedBox(height: 24),

            // 3. PITCH & SPEED CONTROLLER
            _buildSpeedPitchController(context),
            const SizedBox(height: 24),

            // 4. 5-BAND EQUALIZER
            _buildEqualizerSection(context),
            const SizedBox(height: 24),

            // 5. TOP PLAYED TRACKS
            _buildTopPlayedSection(context),
            const SizedBox(height: 100), // padding for mini player
          ],
        ),
      ),
    );
  }

  Widget _buildListeningStatsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.25),
            AppTheme.secondary.withOpacity(0.12),
            AppTheme.cardBg,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryLight.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.insights_rounded, color: AppTheme.primaryLight, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Wawasan Musik Anda',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Hari Ini',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.timer_outlined,
                  value: '${provider.todayMinutesListened} Menit',
                  label: 'Waktu Dengar',
                  color: AppTheme.secondary,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.08)),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.repeat_one_rounded,
                  value: '${provider.history.length}',
                  label: 'Diputar',
                  color: AppTheme.accentPink,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.08)),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.favorite_rounded,
                  value: '${provider.favoriteSongs.length}',
                  label: 'Disukai',
                  color: AppTheme.accentAmber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSoundProfilesGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: SoundProfile.values.map((profile) {
        final isSelected = provider.activeProfile == profile;
        return InkWell(
          onTap: () => provider.setSoundProfile(profile),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accentPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.08),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  profile.icon,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        profile.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${profile.defaultSpeed}x Speed',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white70 : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpeedPitchController(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.speed_rounded, color: AppTheme.secondary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Kecepatan Audio (Tempo & Pitch)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${provider.playbackRate.toStringAsFixed(2)}x',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primary,
              inactiveTrackColor: AppTheme.surfaceLight,
              thumbColor: Colors.white,
              overlayColor: AppTheme.primary.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              trackHeight: 4,
            ),
            child: Slider(
              value: provider.playbackRate,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: (val) => provider.setPlaybackRate(val),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSpeedChip(context, '0.75x Slow', 0.75),
              _buildSpeedChip(context, '1.0x Normal', 1.0),
              _buildSpeedChip(context, '1.25x Up', 1.25),
              _buildSpeedChip(context, '1.5x Fast', 1.5),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedChip(BuildContext context, String label, double speed) {
    final isSelected = (provider.playbackRate - speed).abs() < 0.05;
    return InkWell(
      onTap: () => provider.setPlaybackRate(speed),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight.withOpacity(0.25) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEqualizerSection(BuildContext context) {
    final frequencies = ['60Hz', '230Hz', '910Hz', '3.6k', '14kHz'];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.equalizer_rounded, color: AppTheme.accentPink, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '5-Band Equalizer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => provider.toggleSpatialAudio(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: provider.spatialAudioEnabled
                        ? AppTheme.accentPink.withOpacity(0.2)
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.surround_sound_rounded,
                        size: 14,
                        color: provider.spatialAudioEnabled ? AppTheme.accentPink : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        provider.spatialAudioEnabled ? '3D Aktif' : '3D Mati',
                        style: TextStyle(
                          fontSize: 11,
                          color: provider.spatialAudioEnabled ? AppTheme.accentPink : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              final gain = provider.equalizerBands[index];
              return Column(
                children: [
                  Text(
                    (gain > 0 ? '+' : '') + gain.toStringAsFixed(1) + 'dB',
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
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPlayedSection(BuildContext context) {
    final topSongs = provider.topPlayedSongs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lagu Sering Diputar 🏆',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: topSongs.length > 4 ? 4 : topSongs.length,
          itemBuilder: (context, index) {
            final song = topSongs[index];
            final isCurrent = provider.currentSong?.id == song.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isCurrent ? AppTheme.primary.withOpacity(0.12) : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrent ? AppTheme.primary.withOpacity(0.3) : Colors.transparent,
                ),
              ),
              child: ListTile(
                onTap: () => provider.playSong(song),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: index == 0 ? AppTheme.accentAmber : AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    AlbumArtwork(song: song, size: 42, borderRadius: 8),
                  ],
                ),
                title: Text(
                  song.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                ),
                subtitle: Text(
                  '${song.artist} • ${song.playCount}x Putar',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                trailing: Icon(
                  isCurrent && provider.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
