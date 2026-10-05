import 'package:flutter/material.dart';
import '../models/song.dart';

class AlbumArtwork extends StatelessWidget {
  final Song song;
  final double size;
  final double borderRadius;
  final bool showVinylEffect;
  final bool isSpinning;

  const AlbumArtwork({
    super.key,
    required this.song,
    this.size = 60,
    this.borderRadius = 14,
    this.showVinylEffect = false,
    this.isSpinning = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showVinylEffect) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: song.gradientColors.first.withOpacity(0.35),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Vinyl Disc
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                    Color(0xFF020617),
                  ],
                  stops: [0.3, 0.7, 1.0],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 2),
              ),
            ),
            // Grooves
            Container(
              width: size * 0.82,
              height: size * 0.82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
              ),
            ),
            Container(
              width: size * 0.65,
              height: size * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
              ),
            ),
            // Center Center Artwork Label
            ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.25),
              child: SizedBox(
                width: size * 0.5,
                height: size * 0.5,
                child: _buildArtworkContent(),
              ),
            ),
            // Spindle Hole
            Container(
              width: size * 0.1,
              height: size * 0.1,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0D1117),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: song.gradientColors.first.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _buildArtworkContent(),
      ),
    );
  }

  Widget _buildArtworkContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base Rich Gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: song.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Stylized Mesh Pattern / Icon
        Center(
          child: Icon(
            song.genreIcon,
            color: Colors.white.withOpacity(0.85),
            size: size * 0.38,
          ),
        ),
        // Network Image with Fade and Fallback
        Image.network(
          song.coverUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox();
          },
          errorBuilder: (context, error, stackTrace) {
            // Graceful styled fallback without broken icon
            return Center(
              child: Icon(
                song.genreIcon,
                color: Colors.white.withOpacity(0.9),
                size: size * 0.4,
              ),
            );
          },
        ),
        // Glass sheen overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.transparent,
                Colors.black.withOpacity(0.35),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}
