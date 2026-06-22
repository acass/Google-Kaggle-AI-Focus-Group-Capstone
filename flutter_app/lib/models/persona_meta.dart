class PersonaMeta {
  final String id;
  final String name;
  final String role;
  final String communicationStyle;

  const PersonaMeta({
    required this.id,
    required this.name,
    required this.role,
    required this.communicationStyle,
  });

  factory PersonaMeta.fromJson(Map<String, dynamic> j) => PersonaMeta(
        id: j['id'] as String,
        name: j['name'] as String,
        role: j['role'] as String,
        communicationStyle: (j['communication_style'] as String?) ?? '',
      );
}
