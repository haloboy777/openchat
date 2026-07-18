import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/open_router_model.dart';
import '../models/chat_message.dart';

/// Spend reported by OpenRouter for the current API key (GET /key).
class KeyUsage {
  final double usage;
  final double usageDaily;
  final double usageWeekly;
  final double usageMonthly;
  final double? limit;
  final double? limitRemaining;

  KeyUsage({
    required this.usage,
    required this.usageDaily,
    required this.usageWeekly,
    required this.usageMonthly,
    this.limit,
    this.limitRemaining,
  });

  factory KeyUsage.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) => ((v ?? 0) as num).toDouble();
    return KeyUsage(
      usage: toDouble(json['usage']),
      usageDaily: toDouble(json['usage_daily']),
      usageWeekly: toDouble(json['usage_weekly']),
      usageMonthly: toDouble(json['usage_monthly']),
      limit: (json['limit'] as num?)?.toDouble(),
      limitRemaining: (json['limit_remaining'] as num?)?.toDouble(),
    );
  }
}

/// Cost and token counts reported by OpenRouter at the end of a stream.
class UsageInfo {
  final double cost;
  final int promptTokens;
  final int completionTokens;

  UsageInfo({
    required this.cost,
    required this.promptTokens,
    required this.completionTokens,
  });
}

class ApiService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';

  /// Remaining credits: total purchased minus total used.
  Future<double> fetchBalance(String apiKey) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/credits'),
      headers: {
        'Authorization': 'Bearer $apiKey',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load credits');
    }
    final data = json.decode(response.body)['data'];
    final totalCredits = ((data['total_credits'] ?? 0) as num).toDouble();
    final totalUsage = ((data['total_usage'] ?? 0) as num).toDouble();
    return totalCredits - totalUsage;
  }

  /// Spend for the current key as tracked by OpenRouter itself.
  Future<KeyUsage> fetchKeyUsage(String apiKey) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/key'),
      headers: {
        'Authorization': 'Bearer $apiKey',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load key usage');
    }
    return KeyUsage.fromJson(json.decode(response.body)['data']);
  }

  Future<List<OpenRouterModel>> fetchModels(String apiKey) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/models'),
      headers: {
        'Authorization': 'Bearer $apiKey',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List models = data['data'];
      return models.map((m) => OpenRouterModel.fromJson(m)).toList();
    } else {
      throw Exception('Failed to load models');
    }
  }

  /// Single non-streaming completion. Used for small utility generations
  /// (e.g. profile greetings), not for chat.
  Future<String> chatCompletion({
    required String apiKey,
    required String model,
    String? systemPrompt,
    required String userMessage,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://github.com/haloboy777/openchat',
      },
      body: json.encode({
        'model': model,
        'messages': [
          if (systemPrompt != null) {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Completion failed: ${response.body}');
    }
    final content =
        json.decode(response.body)['choices'][0]['message']['content'];
    if (content is! String || content.trim().isEmpty) {
      throw Exception('Empty completion');
    }
    return content.trim();
  }

  Stream<String> chatCompletionStream({
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
    void Function(UsageInfo usage)? onUsage,
  }) async* {
    final url = Uri.parse('$_baseUrl/chat/completions');
    
    final request = http.Request('POST', url);
    request.headers.addAll({
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://github.com/haloboy777/openchat', // Optional for OpenRouter
    });

    request.body = json.encode({
      'model': model,
      'messages': messages.map((m) => {
        'role': m.role,
        'content': m.content,
      }).toList(),
      'stream': true,
      // Ask OpenRouter to report cost/tokens in the final stream chunk.
      'usage': {'include': true},
    });

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        throw Exception('Failed to get chat completion: $errorBody');
      }

      await for (final chunk in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (chunk.startsWith('data: ')) {
          final data = chunk.substring(6);
          if (data == '[DONE]') break;

          try {
            final decoded = json.decode(data);

            final usage = decoded['usage'];
            if (usage is Map) {
              onUsage?.call(UsageInfo(
                cost: ((usage['cost'] ?? 0) as num).toDouble(),
                promptTokens: ((usage['prompt_tokens'] ?? 0) as num).toInt(),
                completionTokens:
                    ((usage['completion_tokens'] ?? 0) as num).toInt(),
              ));
            }

            final choices = decoded['choices'];
            if (choices is List && choices.isNotEmpty) {
              final content = choices[0]['delta']?['content'] ?? '';
              if (content.isNotEmpty) {
                yield content;
              }
            }
          } catch (e) {
            // Ignore parse errors for incomplete chunks
          }
        }
      }
    } finally {
      client.close();
    }
  }
}
