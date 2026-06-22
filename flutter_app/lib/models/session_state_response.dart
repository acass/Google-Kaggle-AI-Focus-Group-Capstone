import 'final_report.dart';

/// Subset of GET /sessions/{id} that the client actually consumes. The
/// `done` handler reads this purely to obtain the populated final_report.
class SessionStateResponse {
  final String sessionId;
  final String topic;
  final String phase;
  final FinalReport? finalReport;
  final bool completed;

  const SessionStateResponse({
    required this.sessionId,
    required this.topic,
    required this.phase,
    required this.finalReport,
    required this.completed,
  });

  factory SessionStateResponse.fromJson(Map<String, dynamic> j) =>
      SessionStateResponse(
        sessionId: (j['session_id'] as String?) ?? '',
        topic: (j['topic'] as String?) ?? '',
        phase: (j['phase'] as String?) ?? '',
        finalReport: j['final_report'] == null
            ? null
            : FinalReport.fromJson(j['final_report'] as Map<String, dynamic>),
        completed: (j['completed'] as bool?) ?? false,
      );
}

class CreateSessionResponse {
  final String sessionId;
  final String topic;

  const CreateSessionResponse({required this.sessionId, required this.topic});

  factory CreateSessionResponse.fromJson(Map<String, dynamic> j) =>
      CreateSessionResponse(
        sessionId: j['session_id'] as String,
        topic: (j['topic'] as String?) ?? '',
      );
}
