class ChatSession {
  final String id;
  final String title;
  final DateTime lastUpdated;

  ChatSession({
    required this.id,
    required this.title,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'],
      title: map['title'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }

  ChatSession copyWith({String? title, DateTime? lastUpdated}) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
