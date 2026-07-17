import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat/models/usage_stats.dart';
import 'package:open_chat/services/api_service.dart';
import 'package:open_chat/utils/ui_utils.dart';

void main() {
  group('UsageRecord', () {
    test('round-trips through toMap/fromMap', () {
      final record = UsageRecord(
        id: 'u1',
        model: 'anthropic/claude-sonnet-5',
        cost: 0.0042,
        promptTokens: 1200,
        completionTokens: 350,
        timestamp: DateTime(2026, 7, 18, 4, 40),
      );
      final restored = UsageRecord.fromMap(record.toMap());
      expect(restored.id, record.id);
      expect(restored.model, record.model);
      expect(restored.cost, record.cost);
      expect(restored.promptTokens, record.promptTokens);
      expect(restored.completionTokens, record.completionTokens);
      expect(restored.timestamp, record.timestamp);
    });
  });

  group('KeyUsage', () {
    test('parses the /key response fields', () {
      final usage = KeyUsage.fromJson({
        'usage': 25.5,
        'usage_daily': 0.5,
        'usage_weekly': 3.2,
        'usage_monthly': 12,
        'limit': 100,
        'limit_remaining': 74.5,
      });
      expect(usage.usage, 25.5);
      expect(usage.usageDaily, 0.5);
      expect(usage.usageWeekly, 3.2);
      expect(usage.usageMonthly, 12.0);
      expect(usage.limit, 100.0);
      expect(usage.limitRemaining, 74.5);
    });

    test('tolerates missing fields', () {
      final usage = KeyUsage.fromJson({'usage': 1.0});
      expect(usage.usageDaily, 0.0);
      expect(usage.limit, isNull);
      expect(usage.limitRemaining, isNull);
    });
  });

  group('formatCost', () {
    test('zero shows as \$0.00', () {
      expect(formatCost(0), '\$0.00');
    });

    test('sub-cent amounts show as <\$0.01', () {
      expect(formatCost(0.0042), '<\$0.01');
    });

    test('normal amounts show two decimals', () {
      expect(formatCost(21.7), '\$21.70');
    });
  });

  group('formatRelativeTime', () {
    final now = DateTime(2026, 7, 18, 12, 0);

    test('under a minute is "just now"', () {
      expect(formatRelativeTime(now.subtract(const Duration(seconds: 30)), now: now), 'just now');
    });

    test('minutes ago', () {
      expect(formatRelativeTime(now.subtract(const Duration(minutes: 4)), now: now), '4 min ago');
    });

    test('hours ago', () {
      expect(formatRelativeTime(now.subtract(const Duration(hours: 3)), now: now), '3 h ago');
    });

    test('older than a day shows the date', () {
      expect(formatRelativeTime(DateTime(2026, 7, 10, 9, 15), now: now), 'Jul 10, 09:15');
    });
  });
}
