import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat/models/chat_message.dart';
import 'package:open_chat/models/chat_session.dart';
import 'package:open_chat/models/open_router_model.dart';

void main() {
  group('ChatMessage', () {
    final message = ChatMessage(
      id: 'm1',
      sessionId: 's1',
      role: 'user',
      content: 'hello',
      timestamp: DateTime(2026, 7, 18, 12, 30),
    );

    test('round-trips through toMap/fromMap', () {
      final restored = ChatMessage.fromMap(message.toMap());
      expect(restored.id, message.id);
      expect(restored.sessionId, message.sessionId);
      expect(restored.role, message.role);
      expect(restored.content, message.content);
      expect(restored.timestamp, message.timestamp);
    });

    test('copyWith replaces content and keeps everything else', () {
      final copy = message.copyWith(content: 'edited');
      expect(copy.content, 'edited');
      expect(copy.id, message.id);
      expect(copy.timestamp, message.timestamp);
    });
  });

  group('ChatSession', () {
    final session = ChatSession(
      id: 's1',
      title: 'My chat',
      lastUpdated: DateTime(2026, 7, 18),
    );

    test('round-trips through toMap/fromMap', () {
      final restored = ChatSession.fromMap(session.toMap());
      expect(restored.id, session.id);
      expect(restored.title, session.title);
      expect(restored.lastUpdated, session.lastUpdated);
    });

    test('copyWith replaces given fields and keeps the rest', () {
      final renamed = session.copyWith(title: 'Renamed');
      expect(renamed.title, 'Renamed');
      expect(renamed.id, session.id);
      expect(renamed.lastUpdated, session.lastUpdated);
    });
  });

  group('OpenRouterModel', () {
    test('derives provider from the id prefix', () {
      final model = OpenRouterModel.fromJson({
        'id': 'openai/gpt-4',
        'name': 'GPT-4',
        'description': 'desc',
      });
      expect(model.provider, 'openai');
    });

    test('falls back to "other" when id has no prefix', () {
      final model = OpenRouterModel.fromJson({'id': 'standalone-model'});
      expect(model.provider, 'other');
      expect(model.name, 'standalone-model');
      expect(model.description, '');
    });

    test('provider survives a cache round-trip through toJson/fromJson', () {
      final model = OpenRouterModel.fromJson({
        'id': 'anthropic/claude-sonnet-5',
        'name': 'Claude Sonnet 5',
      });
      final restored = OpenRouterModel.fromJson(model.toJson());
      expect(restored.provider, 'anthropic');
      expect(restored.name, model.name);
    });
  });
}
