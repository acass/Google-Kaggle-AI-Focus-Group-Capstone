import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

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

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

/// Accumulates WordprocessingML paragraphs, mirroring the addPara/addList
/// helpers in exportReport.ts. Sizes are half-points (22 = 11pt), colors hex.
class _DocBody {
  final StringBuffer _b = StringBuffer();

  void para(
    String text, {
    bool bold = false,
    int size = 22,
    String color = '000000',
    int spacing = 120,
  }) {
    final lines = text.split('\n');
    final runs = StringBuffer();
    for (var i = 0; i < lines.length; i++) {
      final rpr = StringBuffer('<w:rPr>');
      if (bold) rpr.write('<w:b/>');
      rpr.write('<w:sz w:val="$size"/><w:color w:val="$color"/></w:rPr>');
      final br = i > 0 ? '<w:br/>' : '';
      runs.write(
          '<w:r>$rpr$br<w:t xml:space="preserve">${_esc(lines[i])}</w:t></w:r>');
    }
    _b.write(
        '<w:p><w:pPr><w:spacing w:after="$spacing"/></w:pPr>$runs</w:p>');
  }

  void bullet(String text, {int spacing = 80}) {
    _b.write('<w:p><w:pPr>'
        '<w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/></w:numPr>'
        '<w:spacing w:after="$spacing"/></w:pPr>'
        '<w:r><w:rPr><w:sz w:val="20"/></w:rPr>'
        '<w:t xml:space="preserve">${_esc(text)}</w:t></w:r></w:p>');
  }

  void blank(int spacing) {
    _b.write('<w:p><w:pPr><w:spacing w:after="$spacing"/></w:pPr></w:p>');
  }

  String get xml => _b.toString();
}

const _contentTypes = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
    '<Default Extension="xml" ContentType="application/xml"/>'
    '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
    '<Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/>'
    '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>'
    '</Types>';

const _rels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
    '</Relationships>';

const _docRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering" Target="numbering.xml"/>'
    '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
    '</Relationships>';

const _styles = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
    '<w:docDefaults><w:rPrDefault><w:rPr>'
    '<w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/>'
    '</w:rPr></w:rPrDefault></w:docDefaults>'
    '<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style>'
    '</w:styles>';

const _numbering = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
    '<w:abstractNum w:abstractNumId="0"><w:lvl w:ilvl="0">'
    '<w:start w:val="1"/><w:numFmt w:val="bullet"/><w:lvlText w:val="&#8226;"/>'
    '<w:lvlJc w:val="left"/><w:pPr><w:ind w:left="720" w:hanging="360"/></w:pPr>'
    '</w:lvl></w:abstractNum>'
    '<w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num>'
    '</w:numbering>';

/// Builds the .docx report, mirroring exportReport.ts exportAsDocx.
Uint8List buildDocx(FocusGroupSession session) {
  final report = session.finalReport!;
  final body = _DocBody();

  // Topic
  body.para('Topic', size: 28, spacing: 40);
  body.para('“${session.topic}”', size: 22, color: '444444', spacing: 240);

  // Transcript
  for (final evt in session.events) {
    if (evt.type == 'agent_message') {
      body.para(evt.agentName ?? 'Unknown', size: 24, spacing: 40);
      body.para(_phaseLabel(evt.phase), size: 20, color: '666666', spacing: 80);
      body.para(evt.content, size: 20, color: '222222', spacing: 240);
    }
  }

  // Scoring
  body.para('Scoring Phase', size: 28, spacing: 120);
  for (final evt in session.events) {
    if (evt.type == 'score_update' && evt.scores != null) {
      final cats = evt.scores!.orderedEntries
          .map((e) => '${e.key}=${e.value.toStringAsFixed(1)}')
          .join(', ');
      body.para(evt.agentName ?? 'Unknown', size: 24, spacing: 40);
      body.para('Scored: $cats', size: 20, color: '444444', spacing: 160);
    }
  }

  body.blank(240);

  // Summary
  body.para('Status - Complete', bold: true, size: 22, spacing: 40);
  body.para('Sentiment - ${capitalize(report.sentiment)}',
      bold: true, size: 22, spacing: 40);
  body.para('Consensus - ${(report.consensusConfidence * 100).round()}%',
      bold: true, size: 22, spacing: 120);

  body.para(report.overallScore.toStringAsFixed(1),
      bold: true, size: 32, spacing: 40);
  body.para('Overall score / 10', size: 20, color: '666666', spacing: 120);

  body.para('Scores by category', bold: true, size: 24, spacing: 80);
  final cats = <List<dynamic>>[
    ['Innovation', report.categoryAverages.innovation],
    ['Market Potential', report.categoryAverages.market],
    ['UX / Clarity', report.categoryAverages.ux],
    ['Feasibility', report.categoryAverages.feasibility],
    ['Monetization', report.categoryAverages.monetization],
    ['Risk (10 = safe)', report.categoryAverages.risk],
  ];
  for (final c in cats) {
    body.para('${c[0]} - ${(c[1] as double).toStringAsFixed(1)}',
        size: 20, color: '444444', spacing: 40);
  }

  body.blank(240);

  // Final Report
  body.para('Final Report', bold: true, size: 36, spacing: 80);
  body.para(
      '${capitalize(report.sentiment)} — ${(report.consensusConfidence * 100).round()}% Consensus',
      bold: true,
      size: 24,
      color: '555555',
      spacing: 40);
  body.para('${report.overallScore.toStringAsFixed(1)} / 10',
      bold: true, size: 24, color: '555555', spacing: 120);
  body.para(report.recommendation, size: 20, color: '222222', spacing: 160);

  void list(String title, List<String> items) {
    if (items.isEmpty) return;
    body.para(title, bold: true, size: 24, spacing: 80);
    for (final item in items) {
      body.bullet(item, spacing: 80);
    }
    body.blank(80);
  }

  list('Strengths', report.keyStrengths);
  list('Concerns', report.keyConcerns);
  list('Action Items', report.actionItems);

  final document =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:body>${body.xml}<w:sectPr/></w:body></w:document>';

  final archive = Archive();
  void add(String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  add('[Content_Types].xml', _contentTypes);
  add('_rels/.rels', _rels);
  add('word/_rels/document.xml.rels', _docRels);
  add('word/styles.xml', _styles);
  add('word/numbering.xml', _numbering);
  add('word/document.xml', document);

  final zipped = ZipEncoder().encode(archive);
  return Uint8List.fromList(zipped);
}
