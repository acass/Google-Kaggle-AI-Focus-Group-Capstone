import 'package:flutter_test/flutter_test.dart';
import 'package:focus_group/models/session_state_response.dart';

void main() {
  group('SessionStateResponse.fromJson', () {
    test('parses all fields', () {
      final r = SessionStateResponse.fromJson({
        'session_id': 'abc-123',
        'topic': 'My startup idea',
        'phase': 'independent',
        'final_report': null,
        'completed': false,
      });
      expect(r.sessionId, 'abc-123');
      expect(r.topic, 'My startup idea');
      expect(r.phase, 'independent');
      expect(r.finalReport, isNull);
      expect(r.completed, false);
    });

    test('defaults null/missing fields gracefully', () {
      final r = SessionStateResponse.fromJson({});
      expect(r.sessionId, '');
      expect(r.topic, '');
      expect(r.phase, '');
      expect(r.finalReport, isNull);
      expect(r.completed, false);
    });

    test('parses completed = true', () {
      final r = SessionStateResponse.fromJson({
        'session_id': 'xyz',
        'topic': 'done',
        'phase': 'complete',
        'final_report': null,
        'completed': true,
      });
      expect(r.completed, true);
    });
  });

  group('CreateSessionResponse.fromJson', () {
    test('parses session_id and topic', () {
      final r = CreateSessionResponse.fromJson({
        'session_id': 'sess-001',
        'topic': 'New Product',
        'participant_ids': ['skeptical_investor'],
      });
      expect(r.sessionId, 'sess-001');
      expect(r.topic, 'New Product');
    });

    test('defaults empty topic when omitted', () {
      final r = CreateSessionResponse.fromJson({'session_id': 's'});
      expect(r.topic, '');
    });
  });
}
