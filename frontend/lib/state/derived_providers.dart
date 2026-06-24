import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/format.dart';
import '../models/score_set.dart';
import 'session_notifier.dart';

final isRunningProvider = Provider<bool>((ref) {
  final s = ref.watch(sessionProvider).session;
  return s != null && !s.completed;
});

final showReportProvider = Provider<bool>((ref) {
  final s = ref.watch(sessionProvider).session;
  return s != null && s.completed && s.finalReport != null;
});

/// Mirrors ScorePanel.averageScores: report averages if present, otherwise the
/// mean of the live per-agent scores (each category rounded to 1 dp).
final averageScoresProvider = Provider<ScoreSet?>((ref) {
  final s = ref.watch(sessionProvider).session;
  if (s == null) return null;
  if (s.finalReport != null) return s.finalReport!.categoryAverages;
  return _averageOf(s.scores);
});

final overallScoreProvider = Provider<double?>((ref) {
  final s = ref.watch(sessionProvider).session;
  if (s == null) return null;
  if (s.finalReport != null) return s.finalReport!.overallScore;
  final avg = ref.watch(averageScoresProvider);
  if (avg == null) return null;
  return round1(avg.average);
});

ScoreSet? _averageOf(Map<String, ScoreSet> scores) {
  if (scores.isEmpty) return null;
  final list = scores.values.toList();
  double avg(double Function(ScoreSet) pick) =>
      round1(list.map(pick).reduce((a, b) => a + b) / list.length);
  return ScoreSet(
    innovation: avg((s) => s.innovation),
    market: avg((s) => s.market),
    ux: avg((s) => s.ux),
    feasibility: avg((s) => s.feasibility),
    monetization: avg((s) => s.monetization),
    risk: avg((s) => s.risk),
  );
}
