import 'package:printing/printing.dart';

import '../models/focus_group_session.dart';
import 'docx_builder.dart';
import 'pdf_builder.dart';
import 'web_download.dart';

const _docxMime =
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

Future<void> exportAsPdf(FocusGroupSession session) async {
  final bytes = await buildPdf(session);
  await Printing.sharePdf(bytes: bytes, filename: 'focus-group-report.pdf');
}

Future<void> exportAsDocx(FocusGroupSession session) async {
  final bytes = buildDocx(session);
  downloadBytes(bytes, 'focus-group-report.docx', _docxMime);
}
