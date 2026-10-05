import 'dart:math';
import 'package:flutter/material.dart';

class LiveVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color barColor;
  final int barCount;
  final double maxHeight;
  final double barWidth;

  const LiveVisualizer({
    super.key,
    required this.isPlaying,
    this.barColor = const Color(0xFF6366F1),
    this.barCount = 4,
    this.maxHeight = 24.0,
    this.barWidth = 3.5,
  });

  @override
  State<LiveVisualizer> createState() => _LiveVisualizerState();
}

class _LiveVisualizerState extends State<LiveVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // removed unused random

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying) {
      return SizedBox(
        height: widget.maxHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.barCount, (index) {
            return Container(
              width: widget.barWidth,
              height: 4.0,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: widget.barColor.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: widget.maxHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.barCount, (index) {
              final wave = sin((_controller.value * 2 * pi) + (index * 0.8)).abs();
              final height = 4.0 + (wave * (widget.maxHeight - 4.0));
              return Container(
                width: widget.barWidth,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.barColor,
                      widget.barColor.withOpacity(0.6),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: widget.barColor.withOpacity(0.4),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
