import 'package:flutter/material.dart';

import '../../../app/format.dart';
import '../../../app/theme.dart';
import '../../../models/stream_event.dart';

const _phaseLabels = {
  'intro': 'Introduction',
  'independent': 'Round 1 — Independent',
  'discussion': 'Round 2 — Discussion',
  'voting': 'Scoring',
  'synthesis': 'Synthesis',
};

class _PhaseStyle {
  final Color fg;
  final Color bg;
  final Color border;
  const _PhaseStyle(this.fg, this.bg, this.border);
}

_PhaseStyle _phaseStyle(String phase) {
  switch (phase) {
    case 'intro':
      return const _PhaseStyle(AppColors.blue400, Color(0x1A3B82F6), Color(0x333B82F6));
    case 'independent':
      return const _PhaseStyle(AppColors.amber400, Color(0x1AF59E0B), Color(0x33F59E0B));
    case 'discussion':
      return const _PhaseStyle(AppColors.emerald400, Color(0x1A10B981), Color(0x3310B981));
    case 'voting':
      return const _PhaseStyle(AppColors.purple400, Color(0x1AA855F7), Color(0x33A855F7));
    case 'synthesis':
      return const _PhaseStyle(AppColors.rose400, Color(0x1AF43F5E), Color(0x33F43F5E));
    default:
      return const _PhaseStyle(AppColors.zinc400, Color(0x1A71717A), Color(0x3371717A));
  }
}

String _initials(String? name) {
  if (name == null || name.isEmpty) return '?';
  final parts = name.split(' ').where((p) => p.isNotEmpty).take(2);
  return parts.map((p) => p[0]).join().toUpperCase();
}

class AgentBubble extends StatelessWidget {
  final StreamEvent event;
  const AgentBubble({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final avatarColor =
        AppColors.agentColors[event.agentId ?? ''] ?? AppColors.zinc600;
    final ps = _phaseStyle(event.phase);
    final phaseLabel = _phaseLabels[event.phase] ?? event.phase;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x9927272A))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              _initials(event.agentName),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      event.agentName ?? '',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ps.bg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: ps.border),
                      ),
                      child: Text(phaseLabel,
                          style: TextStyle(fontSize: 10, color: ps.fg)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.content,
                  style: const TextStyle(
                      fontSize: 14, height: 1.5, color: AppColors.zinc300),
                ),
                if (event.scores != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: event.scores!.orderedEntries
                        .map((e) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.zinc800,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('${e.key} ${fmtNum(e.value)}/10',
                                  style: const TextStyle(
                                      fontSize: 10, color: AppColors.zinc400)),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
