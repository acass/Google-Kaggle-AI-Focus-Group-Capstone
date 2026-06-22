import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../state/derived_providers.dart';
import '../../state/session_notifier.dart';
import 'widgets/discussion_thread.dart';
import 'widgets/final_report_card.dart';
import 'widgets/score_panel.dart';
import 'widgets/topic_input.dart';

class FocusGroupPage extends ConsumerWidget {
  const FocusGroupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(sessionProvider).error;
    final showReport = ref.watch(showReportProvider);

    return Scaffold(
      backgroundColor: AppColors.zinc950,
      body: Column(
        children: [
          // Header
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.zinc800)),
            ),
            child: Row(
              children: [
                const Text('Synthetic Market Intelligence Platform',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white)),
                if (error != null) ...[
                  const Spacer(),
                  Flexible(
                    child: Text(error,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.red400)),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left panel
                Container(
                  width: 256,
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: AppColors.zinc800)),
                  ),
                  child: const SingleChildScrollView(child: TopicInput()),
                ),
                // Center
                Expanded(
                  child: Column(
                    children: [
                      const Expanded(child: DiscussionThread()),
                      if (showReport)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 384),
                          decoration: const BoxDecoration(
                            border: Border(
                                top: BorderSide(color: AppColors.zinc800)),
                          ),
                          child: const SingleChildScrollView(
                              child: FinalReportCard()),
                        ),
                    ],
                  ),
                ),
                // Right panel
                Container(
                  width: 224,
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: AppColors.zinc800)),
                  ),
                  child: const ScorePanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
