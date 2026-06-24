import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/persona_meta.dart';
import '../models/session_state_response.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient(this.baseUrl, [http.Client? client])
      : _client = client ?? http.Client();

  Future<List<PersonaMeta>> getPersonas() async {
    final res = await _client.get(Uri.parse('$baseUrl/personas'));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data.values
        .map((v) => PersonaMeta.fromJson(v as Map<String, dynamic>))
        .toList();
  }

  Future<CreateSessionResponse> createSession(
    String topic,
    List<String> participantIds,
  ) async {
    final res = await _client.post(
      Uri.parse('$baseUrl/sessions'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'topic': topic, 'participant_ids': participantIds}),
    );
    if (res.statusCode != 200) {
      String detail = 'Failed to create session';
      try {
        detail = (jsonDecode(res.body) as Map<String, dynamic>)['detail']
                ?.toString() ??
            detail;
      } catch (_) {}
      throw Exception(detail);
    }
    return CreateSessionResponse.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<SessionStateResponse> getSession(String sessionId) async {
    final res = await _client.get(Uri.parse('$baseUrl/sessions/$sessionId'));
    return SessionStateResponse.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }
}
