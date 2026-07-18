class SystemPromptProfile {
  final String id;
  final String name;
  final String prompt;

  /// Short LLM-generated greeting in this profile's persona, cached so it is
  /// only generated once per prompt change. Null until generated.
  final String? greeting;

  SystemPromptProfile({
    required this.id,
    required this.name,
    required this.prompt,
    this.greeting,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'prompt': prompt,
      'greeting': greeting,
    };
  }

  factory SystemPromptProfile.fromJson(Map<String, dynamic> json) {
    return SystemPromptProfile(
      id: json['id'],
      name: json['name'],
      prompt: json['prompt'],
      greeting: json['greeting'],
    );
  }

  SystemPromptProfile copyWith({
    String? name,
    String? prompt,
    String? greeting,
    bool clearGreeting = false,
  }) {
    return SystemPromptProfile(
      id: id,
      name: name ?? this.name,
      prompt: prompt ?? this.prompt,
      greeting: clearGreeting ? null : (greeting ?? this.greeting),
    );
  }
}
