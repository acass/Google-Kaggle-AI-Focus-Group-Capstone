import 'package:flutter_test/flutter_test.dart';
import 'package:focus_group/models/score_set.dart';

void main() {
  const sampleJson = <String, dynamic>{
    'innovation': 8,
    'market': 7.5,
    'ux': 6,
    'feasibility': 7,
    'monetization': 5,
    'risk': 9,
  };

  group('ScoreSet.fromJson', () {
    test('parses integer values as doubles', () {
      final s = ScoreSet.fromJson(sampleJson);
      expect(s.innovation, 8.0);
      expect(s.risk, 9.0);
    });

    test('parses double values', () {
      final s = ScoreSet.fromJson(sampleJson);
      expect(s.market, 7.5);
    });

    test('orderedEntries returns six entries in canonical order', () {
      final s = ScoreSet.fromJson(sampleJson);
      expect(
        s.orderedEntries.map((e) => e.key).toList(),
        ['innovation', 'market', 'ux', 'feasibility', 'monetization', 'risk'],
      );
    });

    test('orderedEntries values match parsed fields', () {
      final s = ScoreSet.fromJson(sampleJson);
      final values = s.orderedEntries.map((e) => e.value).toList();
      expect(values, [8.0, 7.5, 6.0, 7.0, 5.0, 9.0]);
    });
  });

  group('ScoreSet.average', () {
    test('computes the mean of all six categories', () {
      final s = ScoreSet.fromJson(sampleJson);
      // (8 + 7.5 + 6 + 7 + 5 + 9) / 6 = 42.5 / 6
      expect(s.average, closeTo(42.5 / 6, 0.0001));
    });

    test('uniform scores give that value as the average', () {
      const s = ScoreSet(
        innovation: 5.0,
        market: 5.0,
        ux: 5.0,
        feasibility: 5.0,
        monetization: 5.0,
        risk: 5.0,
      );
      expect(s.average, 5.0);
    });
  });
}
