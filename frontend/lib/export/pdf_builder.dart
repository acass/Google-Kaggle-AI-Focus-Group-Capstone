import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../app/format.dart';
import '../models/focus_group_session.dart';

String _phaseLabel(String phase) {
  switch (phase) {
    case 'intro':
      return 'Introduction';
    case 'independent':
      return 'Round 1 — Independent';
    case 'discussion':
      return 'Round 2 — Discussion';
    case 'voting':
      return 'Scoring Phase';
    case 'synthesis':
      return 'Synthesis';
    default:
      return phase;
  }
}

PdfColor _grey(int v) => PdfColor(v / 255, v / 255, v / 255);

/// Builds the PDF report, mirroring the content/order of exportReport.ts.
Future<Uint8List> buildPdf(FocusGroupSession session) async {
  final report = session.finalReport!;
  final doc = pw.Document();
  final items = <pw.Widget>[];

  pw.Widget text(
    String value, {
    double size = 10,
    bool bold = false,
    PdfColor? color,
    double after = 4,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: after),
      child: pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: size,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  // Topic
  items.add(text('Topic', size: 14, bold: true, after: 2));
  items.add(text('“${session.topic}”',
      size: 11, color: _grey(60), after: 10));

  // Transcript
  for (final evt in session.events) {
    if (evt.type == 'agent_message') {
      items.add(text(evt.agentName ?? 'Unknown', size: 12, bold: true, after: 2));
      items.add(text(_phaseLabel(evt.phase), size: 10, color: _grey(100), after: 4));
      items.add(text(evt.content, size: 10, color: _grey(40), after: 10));
    }
  }

  // Scoring
  items.add(text('Scoring Phase', size: 14, bold: true, after: 6));
  for (final evt in session.events) {
    if (evt.type == 'score_update' && evt.scores != null) {
      final cats = evt.scores!.orderedEntries
          .map((e) => '${e.key}=${e.value.toStringAsFixed(1)}')
          .join(', ');
      items.add(text(evt.agentName ?? 'Unknown', size: 12, bold: true, after: 2));
      items.add(text('Scored: $cats', size: 10, color: _grey(60), after: 8));
    }
  }

  items.add(pw.SizedBox(height: 5));

  // Summary header
  items.add(text('Status - Complete', size: 11, bold: true, after: 2));
  items.add(text('Sentiment - ${capitalize(report.sentiment)}',
      size: 11, bold: true, after: 2));
  items.add(text(
      'Consensus - ${(report.consensusConfidence * 100).round()}%',
      size: 11,
      bold: true,
      after: 6));

  items.add(text(report.overallScore.toStringAsFixed(1),
      size: 16, bold: true, after: 2));
  items.add(text('Overall score / 10', size: 10, color: _grey(100), after: 6));

  items.add(text('Scores by category', size: 12, bold: true, after: 4));
  final cats = <List<dynamic>>[
    ['Innovation', report.categoryAverages.innovation],
    ['Market Potential', report.categoryAverages.market],
    ['UX / Clarity', report.categoryAverages.ux],
    ['Feasibility', report.categoryAverages.feasibility],
    ['Monetization', report.categoryAverages.monetization],
    ['Risk (10 = safe)', report.categoryAverages.risk],
  ];
  for (final c in cats) {
    items.add(text('${c[0]} - ${(c[1] as double).toStringAsFixed(1)}',
        size: 10, color: _grey(60), after: 2));
  }
  items.add(pw.SizedBox(height: 8));

  // Final Report
  items.add(text('Final Report', size: 18, bold: true, after: 4));
  items.add(text(
      '${capitalize(report.sentiment)} — ${(report.consensusConfidence * 100).round()}% Consensus',
      size: 12,
      bold: true,
      color: _grey(80),
      after: 2));
  items.add(text('${report.overallScore.toStringAsFixed(1)} / 10',
      size: 12, bold: true, color: _grey(80), after: 6));
  items.add(text(report.recommendation, size: 10, color: _grey(40), after: 8));

  void section(String title, List<String> entries) {
    if (entries.isEmpty) return;
    items.add(text(title, size: 12, bold: true, after: 4));
    for (final entry in entries) {
      items.add(text('•  $entry', size: 10, color: _grey(40), after: 3));
    }
    items.add(pw.SizedBox(height: 4));
  }

  section('Strengths', report.keyStrengths);
  section('Concerns', report.keyConcerns);
  section('Action Items', report.actionItems);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) => items,
    ),
  );

  return doc.save();
}
