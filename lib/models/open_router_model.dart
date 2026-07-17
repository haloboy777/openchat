class OpenRouterModel {
  final String id;
  final String name;
  final String description;
  final String provider;

  OpenRouterModel({
    required this.id,
    required this.name,
    required this.description,
    required this.provider,
  });

  factory OpenRouterModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? '';
    // Extract provider from ID (e.g., "openai/gpt-4" -> "openai")
    final provider = id.contains('/') ? id.split('/').first : 'other';
    
    return OpenRouterModel(
      id: id,
      name: json['name'] ?? id,
      description: json['description'] ?? '',
      provider: provider,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }
}
