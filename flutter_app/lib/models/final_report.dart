import 'score_set.dart';

class FinalReport {
  final double overallScore;
  final Map<String, ScoreSet> scoresByAgent;
  final ScoreSet categoryAverages;
  final ScoreSet categoryStdDev;
  final double consensusConfidence;
  final List<String> keyConcerns;
  final List<String> keyStrengths;
  final List<String> actionItems;
  final String recommendation;
  final String sentiment;
  final List<Map<String, dynamic>> citations;

  const FinalReport({
    required this.overallScore,
    required this.scoresByAgent,
    required this.categoryAverages,
    required this.categoryStdDev,
    required this.consensusConfidence,
    required this.keyConcerns,
    required this.keyStrengths,
    required this.actionItems,
    required this.recommendation,
    required this.sentiment,
    required this.citations,
  });

  factory FinalReport.fromJson(Map<String, dynamic> j) {
    final byAgent = <String, ScoreSet>{};
    final rawByAgent = j['scores_by_agent'] as Map<String, dynamic>? ?? {};
    rawByAgent.forEach((k, v) {
      byAgent[k] = ScoreSet.fromJson(v as Map<String, dynamic>);
    });
    List<String> strs(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    return FinalReport(
      overallScore: (j['overall_score'] as num).toDouble(),
      scoresByAgent: byAgent,
      categoryAverages:
          ScoreSet.fromJson(j['category_averages'] as Map<String, dynamic>),
      categoryStdDev:
          ScoreSet.fromJson(j['category_std_dev'] as Map<String, dynamic>),
      consensusConfidence: (j['consensus_confidence'] as num).toDouble(),
      keyConcerns: strs(j['key_concerns']),
      keyStrengths: strs(j['key_strengths']),
      actionItems: strs(j['action_items']),
      recommendation: (j['recommendation'] as String?) ?? '',
      sentiment: (j['sentiment'] as String?) ?? 'neutral',
      citations: (j['citations'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? [],
    );
  }
}
