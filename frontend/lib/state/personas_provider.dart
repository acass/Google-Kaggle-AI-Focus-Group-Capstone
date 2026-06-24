import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/persona_meta.dart';
import 'session_notifier.dart';

final personasProvider = FutureProvider<List<PersonaMeta>>((ref) async {
  return ref.read(apiClientProvider).getPersonas();
});
