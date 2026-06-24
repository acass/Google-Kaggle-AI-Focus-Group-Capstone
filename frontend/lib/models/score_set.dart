/// Mirrors the backend ScoreSet. The six categories are kept in a fixed order
/// (innovation, market, ux, feasibility, monetization, risk) so the UI and
/// exports iterate them deterministically, matching `Object.entries` in JS.
class ScoreSet {
  final double innovation;
  final double market;
  final double ux;
  final double feasibility;
  final double monetization;
  final double risk;

  const ScoreSet({
    required this.innovation,
    required this.market,
    required this.ux,
    required this.feasibility,
    required this.monetization,
    required this.risk,
  });

  factory ScoreSet.fromJson(Map<String, dynamic> j) => ScoreSet(
        innovation: (j['innovation'] as num).toDouble(),
        market: (j['market'] as num).toDouble(),
        ux: (j['ux'] as num).toDouble(),
        feasibility: (j['feasibility'] as num).toDouble(),
        monetization: (j['monetization'] as num).toDouble(),
        risk: (j['risk'] as num).toDouble(),
      );

  /// Raw category key -> value, in display order (keys match the backend).
  List<MapEntry<String, double>> get orderedEntries => [
        MapEntry('innovation', innovation),
        MapEntry('market', market),
        MapEntry('ux', ux),
        MapEntry('feasibility', feasibility),
        MapEntry('monetization', monetization),
        MapEntry('risk', risk),
      ];

  double get average =>
      (innovation + market + ux + feasibility + monetization + risk) / 6;
}
