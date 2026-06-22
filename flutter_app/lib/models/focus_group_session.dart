import 'final_report.dart';
import 'phase.dart';
import 'score_set.dart';
import 'stream_event.dart';

/// Client-side aggregate of a running/finished session. Mirrors the
/// FocusGroupSession TS interface and is rebuilt immutably on each event.
class FocusGroupSession {
  final String sessionId;
  final String topic;
  final Phase phase;
  final List<StreamEvent> events;
  final Map<String, ScoreSet> scores;
  final FinalReport? finalReport;
  final bool completed;

  const FocusGroupSession({
    required this.sessionId,
    required this.topic,
    required this.phase,
    required this.events,
    required this.scores,
    required this.finalReport,
    required this.completed,
  });

  factory FocusGroupSession.initial({
    required String sessionId,
    required String topic,
  }) =>
      FocusGroupSession(
        sessionId: sessionId,
        topic: topic,
        phase: Phase.intro,
        events: const [],
        scores: const {},
        finalReport: null,
        completed: false,
      );

  static const Object _undefined = Object();

  FocusGroupSession copyWith({
    Phase? phase,
    List<StreamEvent>? events,
    Map<String, ScoreSet>? scores,
    Object? finalReport = _undefined,
    bool? completed,
  }) =>
      FocusGroupSession(
        sessionId: sessionId,
        topic: topic,
        phase: phase ?? this.phase,
        events: events ?? this.events,
        scores: scores ?? this.scores,
        finalReport: identical(finalReport, _undefined)
            ? this.finalReport
            : finalReport as FinalReport?,
        completed: completed ?? this.completed,
      );
}
