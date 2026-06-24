import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_group/models/stream_event.dart';

void main() {
  group('StreamEvent.fromJson', () {
    test('parses an agent_message with no scores', () {
      final e = StreamEvent.fromJson(jsonDecode(
          '{"type":"agent_message","agent_id":"skeptical_investor","agent_name":"Marcus Chen (Skeptical Investor)","phase":"independent","content":"Hello","scores":null}'));
      expect(e.type, 'agent_message');
      expect(e.agentId, 'skeptical_investor');
      expect(e.phase, 'independent');
      expect(e.content, 'Hello');
      expect(e.scores, isNull);
    });

    test('parses a score_update with int and double scores', () {
      final e = StreamEvent.fromJson(jsonDecode(
          '{"type":"score_update","agent_id":"early_adopter","agent_name":"Zoe","phase":"voting","content":"Scored","scores":{"innovation":8,"market":7.5,"ux":6,"feasibility":7,"monetization":5,"risk":9}}'));
      expect(e.type, 'score_update');
      expect(e.scores, isNotNull);
      expect(e.scores!.innovation, 8.0);
      expect(e.scores!.market, 7.5);
      expect(e.scores!.orderedEntries.map((x) => x.key).toList(),
          ['innovation', 'market', 'ux', 'feasibility', 'monetization', 'risk']);
    });

    test('parses the trimmed done event (no agent_id/scores)', () {
      final e = StreamEvent.fromJson(jsonDecode(
          '{"type":"done","phase":"complete","content":"Session complete"}'));
      expect(e.type, 'done');
      expect(e.agentId, isNull);
      expect(e.agentName, isNull);
      expect(e.scores, isNull);
      expect(e.phase, 'complete');
    });

    test('parses the trimmed error event', () {
      final e = StreamEvent.fromJson(jsonDecode(
          '{"type":"error","phase":"error","content":"Boom"}'));
      expect(e.type, 'error');
      expect(e.content, 'Boom');
      expect(e.agentId, isNull);
    });
  });
}
