import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/theme.dart';
import 'features/focus_group/focus_group_page.dart';

void main() {
  runApp(const ProviderScope(child: FocusGroupApp()));
}

class FocusGroupApp extends StatelessWidget {
  const FocusGroupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Focus Group',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const FocusGroupPage(),
    );
  }
}
