import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Three bouncing dots + "Thinking..." shown while a session is in progress.
class ThinkingIndicator extends StatefulWidget {
  const ThinkingIndicator({super.key});

  @override
  State<ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            _Dot(controller: _c, delay: i * 0.15),
            const SizedBox(width: 4),
          ],
          const SizedBox(width: 4),
          const Text('Thinking...',
              style: TextStyle(fontSize: 12, color: AppColors.zinc500)),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  const _Dot({required this.controller, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = (controller.value - delay) % 1.0;
        final offset = t < 0.5 ? -4.0 * (1 - (t * 4 - 1).abs()) : 0.0;
        return Transform.translate(
          offset: Offset(0, offset),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: AppColors.zinc500, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}
