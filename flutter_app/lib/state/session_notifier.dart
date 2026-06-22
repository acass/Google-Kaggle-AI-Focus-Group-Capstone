import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/config.dart';
import '../data/api_client.dart';
import '../data/sse_client.dart';
import '../models/focus_group_session.dart';
import '../models/phase.dart';
import '../models/score_set.dart';
import '../models/stream_event.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(apiBaseUrl));

/// Top-level UI state: the session (or null), plus the loading/error flags
/// the React hook tracked separately.
class FocusGroupState {
  final FocusGroupSession? session;
  final bool isLoading;
  final String? error;

  const FocusGroupState({this.session, this.isLoading = false, this.error});
}

final sessionProvider =
    NotifierProvider<SessionNotifier, FocusGroupState>(SessionNotifier.new);

/// Port of the `useFocusGroup` hook: POST /sessions, open the SSE stream,
/// fold each event into session state, and on `done` fetch the full state to
/// obtain the final_report.
class SessionNotifier extends Notifier<FocusGroupState> {
  SseConnection? _sse;
  StreamSubscription<StreamEvent>? _sub;

  @override
  FocusGroupState build() {
    ref.onDispose(() {
      _sub?.cancel();
      _sse?.close();
    });
    return const FocusGroupState();
  }

  Future<void> start(String topic, List<String> participantIds) async {
    _sub?.cancel();
    _sse?.close();
    _sub = null;
    _sse = null;
    state = const FocusGroupState(isLoading: true);

    final api = ref.read(apiClientProvider);
    try {
      final created = await api.createSession(topic, participantIds);
      state = FocusGroupState(
        session:
            FocusGroupSession.initial(sessionId: created.sessionId, topic: topic),
        isLoading: false,
      );

      _sse = SseConnection('${api.baseUrl}/sessions/${created.sessionId}/stream');
      _sub = _sse!.events.listen(
        (evt) => _applyEvent(evt, created.sessionId),
        onError: (_) {
          final s = state.session;
          if (s != null && !s.completed) {
            state = FocusGroupState(
              session: s,
              error: 'Stream connection lost',
            );
          }
          _sse?.close();
        },
      );
    } catch (e) {
      state = FocusGroupState(error: _message(e), isLoading: false);
    }
  }

  void _applyEvent(StreamEvent evt, String sessionId) {
    final prev = state.session;
    if (prev == null) return;

    var phase = prev.phase;
    final scores = Map<String, ScoreSet>.from(prev.scores);
    var completed = prev.completed;
    var error = state.error;

    switch (evt.type) {
      case 'phase_change':
      case 'agent_message':
        phase = phaseFromString(evt.phase);
        break;
      case 'score_update':
        if (evt.agentId != null && evt.scores != null) {
          scores[evt.agentId!] = evt.scores!;
          phase = Phase.voting;
        }
        break;
      case 'report_complete':
        phase = Phase.synthesis;
        break;
      case 'error':
        error = evt.content.isNotEmpty ? evt.content : 'Session failed';
        _sse?.close();
        break;
      case 'done':
        completed = true;
        phase = Phase.complete;
        _sse?.close();
        break;
    }

    state = FocusGroupState(
      session: prev.copyWith(
        events: [...prev.events, evt],
        phase: phase,
        scores: scores,
        completed: completed,
      ),
      isLoading: false,
      error: error,
    );

    if (evt.type == 'done') {
      _fetchFinalReport(sessionId);
    }
  }

  Future<void> _fetchFinalReport(String sessionId) async {
    try {
      final full = await ref.read(apiClientProvider).getSession(sessionId);
      final s = state.session;
      if (s != null) {
        state = FocusGroupState(
          session: s.copyWith(finalReport: full.finalReport, completed: true),
          isLoading: false,
          error: state.error,
        );
      }
    } catch (_) {
      // ignore, parity with the React .catch(() => {})
    }
  }

  void reset() {
    _sub?.cancel();
    _sse?.close();
    _sub = null;
    _sse = null;
    state = const FocusGroupState();
  }

  String _message(Object e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring('Exception: '.length) : s;
  }
}
