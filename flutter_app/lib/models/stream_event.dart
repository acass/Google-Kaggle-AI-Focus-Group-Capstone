import 'score_set.dart';

/// A single SSE event. Note: the `done` and `error` events omit
/// agent_id/agent_name/scores, so those fields are nullable and parsed
/// defensively.
class StreamEvent {
  final String type;
  final String? agentId;
  final String? agentName;
  final String phase;
  final String content;
  final ScoreSet? scores;

  const StreamEvent({
    required this.type,
    this.agentId,
    this.agentName,
    required this.phase,
    required this.content,
    this.scores,
  });

  factory StreamEvent.fromJson(Map<String, dynamic> j) => StreamEvent(
        type: j['type'] as String,
        agentId: j['agent_id'] as String?,
        agentName: j['agent_name'] as String?,
        phase: (j['phase'] as String?) ?? '',
        content: (j['content'] as String?) ?? '',
        scores: j['scores'] == null
            ? null
            : ScoreSet.fromJson(j['scores'] as Map<String, dynamic>),
      );
}
