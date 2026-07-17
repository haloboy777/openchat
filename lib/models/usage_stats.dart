/// A single completed API request, as recorded locally.
class UsageRecord {
  final String id;
  final String model;
  final double cost;
  final int promptTokens;
  final int completionTokens;
  final DateTime timestamp;

  UsageRecord({
    required this.id,
    required this.model,
    required this.cost,
    required this.promptTokens,
    required this.completionTokens,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'model': model,
      'cost': cost,
      'promptTokens': promptTokens,
      'completionTokens': completionTokens,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory UsageRecord.fromMap(Map<String, dynamic> map) {
    return UsageRecord(
      id: map['id'],
      model: map['model'],
      cost: (map['cost'] as num).toDouble(),
      promptTokens: (map['promptTokens'] as num).toInt(),
      completionTokens: (map['completionTokens'] as num).toInt(),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

/// Aggregated usage for one model.
class ModelUsage {
  final String model;
  final int requests;
  final double cost;
  final int promptTokens;
  final int completionTokens;

  ModelUsage({
    required this.model,
    required this.requests,
    required this.cost,
    required this.promptTokens,
    required this.completionTokens,
  });

  int get totalTokens => promptTokens + completionTokens;
}

/// Token and model breakdown aggregated from this app's local records.
class UsageStats {
  final double totalCost;
  final int totalRequests;
  final int promptTokens;
  final int completionTokens;
  final List<ModelUsage> topModels;

  UsageStats({
    required this.totalCost,
    required this.totalRequests,
    required this.promptTokens,
    required this.completionTokens,
    required this.topModels,
  });

  int get totalTokens => promptTokens + completionTokens;
}
