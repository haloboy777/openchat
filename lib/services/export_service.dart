import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database_service.dart';

/// Exports chat data via the system share sheet.
class ExportService {
  final DatabaseService _dbService = DatabaseService();

  String get _stamp => DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());

  /// Full backup: a copy of the SQLite database file.
  Future<void> exportDatabase() async {
    await _dbService.flushToDisk();
    final src = await _dbService.databaseFilePath();
    final dir = await getTemporaryDirectory();
    final dest = File('${dir.path}/openchat-backup-$_stamp.db');
    await File(src).copy(dest.path);
    await _share(dest.path, 'application/x-sqlite3');
  }

  /// Readable export: all sessions with their messages, as JSON.
  Future<void> exportJson() async {
    final sessions = await _dbService.getSessions();
    final messages = await _dbService.getAllMessages();

    final bySession = <String, List<Map<String, dynamic>>>{};
    for (final message in messages) {
      bySession.putIfAbsent(message.sessionId, () => []).add({
        'id': message.id,
        'role': message.role,
        'content': message.content,
        'timestamp': message.timestamp.toIso8601String(),
      });
    }

    final data = {
      'app': 'OpenChat',
      'exportedAt': DateTime.now().toIso8601String(),
      'sessions': [
        for (final session in sessions)
          {
            'id': session.id,
            'title': session.title,
            'lastUpdated': session.lastUpdated.toIso8601String(),
            'messages': bySession[session.id] ?? [],
          },
      ],
    };

    final dir = await getTemporaryDirectory();
    final dest = File('${dir.path}/openchat-export-$_stamp.json');
    await dest.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    await _share(dest.path, 'application/json');
  }

  Future<void> _share(String path, String mimeType) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path, mimeType: mimeType)]),
    );
  }
}
