import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../models/persona_meta.dart';
import '../../../state/derived_providers.dart';
import '../../../state/personas_provider.dart';
import '../../../state/session_notifier.dart';

class TopicInput extends ConsumerStatefulWidget {
  const TopicInput({super.key});

  @override
  ConsumerState<TopicInput> createState() => _TopicInputState();
}

class _TopicInputState extends ConsumerState<TopicInput> {
  final _controller = TextEditingController();
  final Set<String> _selected = {};
  bool _initialized = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle(String id, bool disabled) {
    if (disabled) return;
    setState(() {
      if (_selected.contains(id)) {
        if (_selected.length > 1) _selected.remove(id);
      } else {
        if (_selected.length < 5) _selected.add(id);
      }
    });
  }

  void _submit() {
    final topic = _controller.text.trim();
    if (topic.isEmpty || _selected.isEmpty) return;
    ref.read(sessionProvider.notifier).start(topic, _selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    final disabled = ref.watch(isRunningProvider);
    final isLoading = ref.watch(sessionProvider).isLoading;
    final personasAsync = ref.watch(personasProvider);

    // Preselect all personas once they load (matches the React effect).
    ref.listen(personasProvider, (prev, next) {
      next.whenData((list) {
        if (!_initialized && list.isNotEmpty) {
          _initialized = true;
          setState(() => _selected.addAll(list.map((p) => p.id)));
        }
      });
    });

    final personas = personasAsync.asData?.value ?? const <PersonaMeta>[];
    final topicEmpty = _controller.text.trim().isEmpty;
    final canSubmit = !disabled && !isLoading && !topicEmpty && _selected.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Focus Group',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white)),
          const SizedBox(height: 4),
          const Text('Submit a topic and get synthetic expert feedback',
              style: TextStyle(fontSize: 12, color: AppColors.zinc400)),
          const SizedBox(height: 16),
          const Text('Topic',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.zinc300)),
          const SizedBox(height: 4),
          TextField(
            controller: _controller,
            enabled: !disabled,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 14, color: AppColors.white),
            decoration: InputDecoration(
              hintText: "e.g. 'Business product or service'",
              hintStyle: const TextStyle(color: AppColors.zinc500),
              filled: true,
              fillColor: AppColors.zinc800,
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.zinc700),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.zinc500),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.zinc700),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Panel (${_selected.length} selected)',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.zinc300)),
          const SizedBox(height: 8),
          ...personas.map((p) => _PersonaButton(
                persona: p,
                selected: _selected.contains(p.id),
                disabled: disabled,
                onTap: () => _toggle(p.id, disabled),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo600,
                disabledBackgroundColor: AppColors.indigo600.withValues(alpha: 0.4),
                foregroundColor: AppColors.white,
                disabledForegroundColor: AppColors.white.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(isLoading ? 'Starting...' : 'Run Focus Group',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonaButton extends StatelessWidget {
  final PersonaMeta persona;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _PersonaButton({
    required this.persona,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? const Color(0x1A6366F1) : const Color(0x8027272A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected ? AppColors.indigo500 : AppColors.zinc700),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(persona.name,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected ? AppColors.white : AppColors.zinc400)),
              const SizedBox(height: 2),
              Text(persona.role,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.zinc500)),
            ],
          ),
        ),
      ),
    );
  }
}
