import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/format.dart';
import '../../../app/theme.dart';
import '../../../models/phase.dart';
import '../../../models/score_set.dart';
import '../../../state/derived_providers.dart';
import '../../../state/session_notifier.dart';

const _categoryLabels = [
  ['innovation', 'Innovation'],
  ['market', 'Market Potential'],
  ['ux', 'UX / Clarity'],
  ['feasibility', 'Feasibility'],
  ['monetization', 'Monetization'],
  ['risk', 'Risk (10 = safe)'],
];

const _phaseStatus = {
  Phase.idle: 'Waiting',
  Phase.intro: 'Introducing...',
  Phase.independent: 'Round 1: Independent eval',
  Phase.discussion: 'Round 2: Group discussion',
  Phase.voting: 'Scoring...',
  Phase.synthesis: 'Synthesizing...',
  Phase.complete: 'Complete',
};

const _sentimentColors = {
  'positive': AppColors.emerald400,
  'neutral': AppColors.zinc400,
  'skeptical': AppColors.amber400,
  'negative': AppColors.red400,
};

double _stdDevFor(ScoreSet s, String key) =>
    s.orderedEntries.firstWhere((e) => e.key == key).value;

double _avgFor(ScoreSet s, String key) =>
    s.orderedEntries.firstWhere((e) => e.key == key).value;

class ScorePanel extends ConsumerWidget {
  const ScorePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).session;
    final phase = session?.phase ?? Phase.idle;
    final scores = session?.scores ?? const <String, ScoreSet>{};
    final report = session?.finalReport;
    final avgScores = ref.watch(averageScoresProvider);
    final overallScore = ref.watch(overallScoreProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Status',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.zinc300)),
            _StatusChip(phase: phase),
          ],
        ),
        if (report != null) ...[
          const SizedBox(height: 8),
          _kv('Sentiment',
              capitalize(report.sentiment),
              valueColor: _sentimentColors[report.sentiment] ?? AppColors.zinc400),
          const SizedBox(height: 4),
          _kv('Consensus', '${(report.consensusConfidence * 100).round()}%',
              valueColor: AppColors.white),
        ],
        const SizedBox(height: 16),
        if (overallScore != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.zinc800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(fmtNum(overallScore),
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white)),
                const SizedBox(height: 2),
                const Text('Overall score / 10',
                    style: TextStyle(fontSize: 12, color: AppColors.zinc400)),
              ],
            ),
          ),
        if (avgScores != null) ...[
          const SizedBox(height: 16),
          const Text('Scores by category',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.zinc300)),
          const SizedBox(height: 8),
          for (final c in _categoryLabels)
            _CategoryRow(
              label: c[1],
              value: _avgFor(avgScores, c[0]),
              stdDev: report == null ? null : _stdDevFor(report.categoryStdDev, c[0]),
            ),
        ],
        if (scores.isNotEmpty && report == null) ...[
          const SizedBox(height: 16),
          const Text('Votes received',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.zinc300)),
          const SizedBox(height: 8),
          for (final entry in scores.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${entry.key.replaceAll('_', ' ')} — avg ${fmtNum(round1(entry.value.average))}',
                style: const TextStyle(fontSize: 12, color: AppColors.zinc500),
              ),
            ),
        ],
        if (avgScores == null)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('Scores will appear during the voting phase',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.zinc500)),
          ),
      ],
    );
  }

  Widget _kv(String label, String value, {required Color valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.zinc400)),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: valueColor)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Phase phase;
  const _StatusChip({required this.phase});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (phase == Phase.complete) {
      bg = const Color(0x3310B981);
      fg = AppColors.emerald400;
    } else if (phase != Phase.idle) {
      bg = const Color(0x336366F1);
      fg = AppColors.indigo400;
    } else {
      bg = AppColors.zinc700;
      fg = AppColors.zinc400;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(_phaseStatus[phase] ?? phase.name,
          style: TextStyle(fontSize: 12, color: fg)),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String label;
  final double value;
  final double? stdDev;
  const _CategoryRow({required this.label, required this.value, this.stdDev});

  @override
  Widget build(BuildContext context) {
    final color = value >= 7
        ? AppColors.emerald500
        : value >= 5
            ? AppColors.amber500
            : AppColors.red500;
    final pct = (value / 10).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: AppColors.zinc400)),
              if (stdDev != null)
                Text('±${fmtNum(stdDev!)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.zinc500)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: AppColors.zinc700,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 24,
                child: Text(fmtNum(value),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, color: AppColors.zinc300)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
