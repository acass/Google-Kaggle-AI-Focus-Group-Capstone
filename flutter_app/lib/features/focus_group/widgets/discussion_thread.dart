import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../models/phase.dart';
import '../../../models/stream_event.dart';
import '../../../state/session_notifier.dart';
import 'agent_bubble.dart';
import 'thinking_indicator.dart';

const _phaseBanners = {
  'discussion': 'Round 2 — Shared Discussion',
  'voting': 'Scoring Phase',
  'synthesis': 'Synthesis',
};

class DiscussionThread extends ConsumerStatefulWidget {
  const DiscussionThread({super.key});

  @override
  ConsumerState<DiscussionThread> createState() => _DiscussionThreadState();
}

class _DiscussionThreadState extends ConsumerState<DiscussionThread> {
  final _scrollController = ScrollController();
  int _lastEventCount = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).session;
    final sessionId = session?.sessionId;
    final phase = session?.phase ?? Phase.idle;
    final events = session?.events ?? const <StreamEvent>[];

    if (events.length != _lastEventCount) {
      _lastEventCount = events.length;
      _autoScroll();
    }

    if (sessionId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('💬', style: TextStyle(fontSize: 36)),
            SizedBox(height: 12),
            Text('Submit a topic to start the focus group',
                style: TextStyle(fontSize: 14, color: AppColors.zinc500)),
          ],
        ),
      );
    }

    final children = <Widget>[];
    final phasesSeen = <String>{};
    for (final evt in events) {
      if (evt.type == 'done') continue;
      final banner = _phaseBanners[evt.phase];
      if (banner != null && !phasesSeen.contains(evt.phase) && evt.phase != 'intro') {
        phasesSeen.add(evt.phase);
        children.add(_Banner(label: banner));
      }
      children.add(AgentBubble(event: evt));
    }

    final isRunning = phase != Phase.idle && phase != Phase.complete;
    if (isRunning) children.add(const ThinkingIndicator());

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: children,
    );
  }
}

class _Banner extends StatelessWidget {
  final String label;
  const _Banner({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.zinc700, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.zinc400)),
          ),
          const Expanded(child: Divider(color: AppColors.zinc700, height: 1)),
        ],
      ),
    );
  }
}
