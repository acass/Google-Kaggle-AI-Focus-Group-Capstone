import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/format.dart';
import '../../../app/theme.dart';
import '../../../export/report_export.dart';
import '../../../models/focus_group_session.dart';
import '../../../state/session_notifier.dart';

const _sentimentBorder = {
  'positive': (Color(0x4D10B981), Color(0x0D10B981)),
  'neutral': (Color(0x4D71717A), Color(0x0D71717A)),
  'skeptical': (Color(0x4DF59E0B), Color(0x0DF59E0B)),
  'negative': (Color(0x4DEF4444), Color(0x0DEF4444)),
};

class FinalReportCard extends ConsumerStatefulWidget {
  const FinalReportCard({super.key});

  @override
  ConsumerState<FinalReportCard> createState() => _FinalReportCardState();
}

class _FinalReportCardState extends ConsumerState<FinalReportCard> {
  bool _pdfLoading = false;
  bool _docxLoading = false;

  Future<void> _handlePdf(FocusGroupSession session) async {
    setState(() => _pdfLoading = true);
    try {
      await exportAsPdf(session);
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  Future<void> _handleDocx(FocusGroupSession session) async {
    setState(() => _docxLoading = true);
    try {
      await exportAsDocx(session);
    } finally {
      if (mounted) setState(() => _docxLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).session;
    if (session == null || session.finalReport == null) {
      return const SizedBox.shrink();
    }
    final report = session.finalReport!;
    final colors = _sentimentBorder[report.sentiment] ?? _sentimentBorder['neutral']!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.$1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Final Report',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white)),
                    const SizedBox(height: 2),
                    Text(
                      '${capitalize(report.sentiment)} — ${(report.consensusConfidence * 100).round()}% consensus',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.zinc400),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(fmtNum(report.overallScore),
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white)),
                  const Text('/ 10',
                      style: TextStyle(fontSize: 10, color: AppColors.zinc400)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(report.recommendation,
              style: const TextStyle(
                  fontSize: 14, height: 1.5, color: AppColors.zinc200)),
          const SizedBox(height: 16),
          if (report.keyStrengths.isNotEmpty)
            _Section(
                title: 'Strengths',
                color: AppColors.emerald400,
                items: report.keyStrengths),
          if (report.keyConcerns.isNotEmpty)
            _Section(
                title: 'Concerns',
                color: AppColors.amber400,
                items: report.keyConcerns),
          if (report.actionItems.isNotEmpty)
            _Section(
                title: 'Action Items',
                color: AppColors.blue400,
                items: report.actionItems),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OutlinedButton(
                  label: _pdfLoading ? 'Generating...' : 'Download PDF',
                  onPressed:
                      _pdfLoading ? null : () => _handlePdf(session),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OutlinedButton(
                  label: _docxLoading ? 'Generating...' : 'Download DOCX',
                  onPressed:
                      _docxLoading ? null : () => _handleDocx(session),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _OutlinedButton(
              label: 'Start new session',
              onPressed: () => ref.read(sessionProvider.notifier).reset(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Color color;
  final List<String> items;
  const _Section({required this.title, required this.color, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 6),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ',
                        style: TextStyle(fontSize: 12, color: AppColors.zinc600)),
                    Expanded(
                      child: Text(item,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.zinc300)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _OutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _OutlinedButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        side: const BorderSide(color: AppColors.zinc700),
        foregroundColor: AppColors.zinc400,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
