import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/open_router_model.dart';
import '../models/usage_stats.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();

  List<ChatSession> _sessions = [];
  ChatSession? _currentSession;
  
  final Map<String, List<ChatMessage>> _sessionMessages = {};
  final Set<String> _streamingSessionIds = {};
  final Map<String, Future<void>> _sessionLocks = {};

  List<OpenRouterModel> _allModels = [];
  List<String>? _selectedProviders;
  DateTime? _lastModelsFetch;
  
  String? _selectedModelId;
  String? _apiKey;
  String? _systemPrompt;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = false;

  double? _balance;
  DateTime? _balanceUpdatedAt;
  KeyUsage? _keyUsage;

  // Error handling
  String? _error;
  String? get error => _error;

  List<ChatSession> get sessions => _sessions;
  ChatSession? get currentSession => _currentSession;
  List<ChatMessage> get messages => _sessionMessages[_currentSession?.id] ?? [];
  
  List<OpenRouterModel> get models {
    if (_selectedProviders == null) return _allModels;
    return _allModels.where((m) => _selectedProviders!.contains(m.provider)).toList();
  }
  
  List<String>? get selectedProviders => _selectedProviders;
  List<String> get availableProviders {
    final providers = _allModels.map((m) => m.provider).toSet().toList();
    providers.sort();
    return providers;
  }
  
  DateTime? get lastModelsFetch => _lastModelsFetch;
  String? get selectedModelId => _selectedModelId;
  String? get apiKey => _apiKey;
  String? get systemPrompt => _systemPrompt;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  bool get isStreaming => _streamingSessionIds.contains(_currentSession?.id);
  bool isSessionStreaming(String sessionId) => _streamingSessionIds.contains(sessionId);
  double? get balance => _balance;
  DateTime? get balanceUpdatedAt => _balanceUpdatedAt;
  KeyUsage? get keyUsage => _keyUsage;

  ChatProvider() {
    _init();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _apiKey = await _storageService.getApiKey();
      _selectedModelId = await _storageService.getSelectedModel();
      _systemPrompt = await _storageService.getSystemPrompt();
      
      final storedTheme = await _storageService.getThemeMode();
      _themeMode = _parseThemeMode(storedTheme);
      
      _selectedProviders = await _storageService.getSelectedProviders();
      _lastModelsFetch = await _storageService.getLastModelsFetch();
      _balance = await _storageService.getBalance();
      _balanceUpdatedAt = await _storageService.getBalanceUpdatedAt();
      
      final cachedJson = await _storageService.getCachedModels();
      if (cachedJson != null) {
        final List decoded = json.decode(cachedJson);
        final models = decoded.map((m) => OpenRouterModel.fromJson(m)).toList();
        _setModels(models);
      }

      _sessions = await _dbService.getSessions();
      
      if (_apiKey != null) {
        await fetchModels();
        // Balance is nice-to-have; don't fail startup over it.
        try {
          await refreshBalance();
        } catch (_) {}
      }

      _validateSelectedModel();
    } catch (e) {
      _error = 'Initialization error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void _setModels(List<OpenRouterModel> models) {
    final Map<String, OpenRouterModel> uniqueModels = {};
    for (var model in models) {
      uniqueModels[model.id] = model;
    }
    _allModels = uniqueModels.values.toList();
    _allModels.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void _validateSelectedModel() {
    if (_allModels.isEmpty) return;
    
    final currentModels = models;
    if (currentModels.isEmpty) return;

    final isStillAvailable = currentModels.any((m) => m.id == _selectedModelId);
    if (!isStillAvailable) {
      _selectedModelId = currentModels.first.id;
      _storageService.saveSelectedModel(_selectedModelId!);
    }
  }

  ThemeMode _parseThemeMode(String? mode) {
    switch (mode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  Future<void> setApiKey(String key) async {
    await _storageService.saveApiKey(key);
    _apiKey = key;
    await fetchModels(forceRefresh: true);
    try {
      await refreshBalance();
    } catch (_) {}
    notifyListeners();
  }

  /// Refreshes the account balance and OpenRouter's own spend figures for
  /// this key. Updates whatever succeeds; rethrows the first failure so
  /// callers that surface errors still can.
  Future<void> refreshBalance() async {
    if (_apiKey == null) return;
    Object? firstError;

    try {
      _balance = await _apiService.fetchBalance(_apiKey!);
      _balanceUpdatedAt = DateTime.now();
      await _storageService.saveBalance(_balance!, _balanceUpdatedAt!);
    } catch (e) {
      firstError = e;
    }

    try {
      _keyUsage = await _apiService.fetchKeyUsage(_apiKey!);
      _balanceUpdatedAt ??= DateTime.now();
    } catch (e) {
      firstError ??= e;
    }

    notifyListeners();
    if (firstError != null) throw firstError;
  }

  Future<UsageStats> getUsageStats() => _dbService.getUsageStats();

  String modelDisplayName(String modelId) {
    for (final model in _allModels) {
      if (model.id == modelId) return model.name;
    }
    return modelId;
  }

  Future<void> setSystemPrompt(String prompt) async {
    await _storageService.saveSystemPrompt(prompt);
    _systemPrompt = prompt;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _storageService.saveThemeMode(mode.name);
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> setProviders(List<String>? providers) async {
    _selectedProviders = providers;
    await _storageService.saveSelectedProviders(providers);
    _validateSelectedModel();
    notifyListeners();
  }

  Future<void> setSelectedModel(String modelId) async {
    await _storageService.saveSelectedModel(modelId);
    _selectedModelId = modelId;
    notifyListeners();
  }

  Future<void> fetchModels({bool forceRefresh = false}) async {
    if (_apiKey == null) return;
    
    bool shouldFetch = forceRefresh || _allModels.isEmpty;
    if (!shouldFetch && _lastModelsFetch != null) {
      final diff = DateTime.now().difference(_lastModelsFetch!);
      if (diff.inHours >= 24) shouldFetch = true;
    }

    if (!shouldFetch) return;

    final fetchedModels = await _apiService.fetchModels(_apiKey!);
    _setModels(fetchedModels);
    _lastModelsFetch = DateTime.now();
    
    final jsonStr = json.encode(_allModels.map((m) => m.toJson()).toList());
    await _storageService.saveCachedModels(jsonStr);
    
    if (_selectedModelId == null && _allModels.isNotEmpty) {
      _selectedModelId = _allModels.first.id;
    }
    
    _validateSelectedModel();
    notifyListeners();
  }

  Future<void> createNewSession() async {
    final session = ChatSession(
      id: const Uuid().v4(),
      title: 'New Chat',
      lastUpdated: DateTime.now(),
    );
    await _upsertSession(session);
    _currentSession = session;
    _sessionMessages[session.id] = [];
    notifyListeners();
  }

  /// Writes [session] to the database, refreshes the session list, and keeps
  /// [_currentSession] pointing at the updated instance.
  Future<void> _upsertSession(ChatSession session) async {
    await _dbService.insertSession(session);
    _sessions = await _dbService.getSessions();
    if (_currentSession?.id == session.id) {
      _currentSession = session;
    }
  }

  Future<void> switchSession(ChatSession session) async {
    _currentSession = session;
    if (!_sessionMessages.containsKey(session.id)) {
      _sessionMessages[session.id] = await _dbService.getMessages(session.id);
    }
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (_currentSession == null) {
      await createNewSession();
    }
    
    if (_apiKey == null || _selectedModelId == null) {
      throw Exception('Please set API key and select a model');
    }

    final sessionId = _currentSession!.id;
    
    // 1. Add user message and update UI immediately
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      sessionId: sessionId,
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );

    _sessionMessages[sessionId] ??= [];
    _sessionMessages[sessionId]!.add(userMessage);
    
    await _dbService.insertMessage(userMessage);
    
    // Update session title if it's the first message
    if (_sessionMessages[sessionId]!.length == 1) {
      final title = content.length > 30 ? '${content.substring(0, 30)}...' : content;
      await _upsertSession(ChatSession(
        id: sessionId,
        title: title,
        lastUpdated: DateTime.now(),
      ));
    }

    notifyListeners();

    // 2. Queue the AI response
    final currentLock = _sessionLocks[sessionId] ?? Future.value();
    _sessionLocks[sessionId] = currentLock.then((_) async {
      await _getAiResponse(sessionId);
    }).catchError((e) {
      _error = e.toString();
      notifyListeners();
    });

    return _sessionLocks[sessionId];
  }

  Future<void> editMessage(ChatMessage oldMessage, String newContent) async {
    final sessionId = _currentSession!.id;
    
    final currentLock = _sessionLocks[sessionId] ?? Future.value();
    _sessionLocks[sessionId] = currentLock.then((_) async {
      await _dbService.deleteMessagesAfter(sessionId, oldMessage.timestamp);
      
      final updatedMessage = oldMessage.copyWith(content: newContent);
      await _dbService.insertMessage(updatedMessage);

      _sessionMessages[sessionId] = await _dbService.getMessages(sessionId);
      notifyListeners();

      await _getAiResponse(sessionId);
    }).catchError((e) {
      _error = e.toString();
      notifyListeners();
    });

    return _sessionLocks[sessionId];
  }

  Future<void> _getAiResponse(String sessionId) async {
    // Hold onto the list itself: if the session is deleted mid-stream the map
    // entry disappears, but this reference stays valid.
    final messages = _sessionMessages[sessionId];
    if (messages == null) return;
    if (messages.isNotEmpty && messages.last.role == 'assistant') {
      // A response was already generated (likely by a previous queued call
      // that saw the newer user messages)
      return;
    }

    _streamingSessionIds.add(sessionId);
    notifyListeners();

    final assistantMessageId = const Uuid().v4();
    String assistantContent = '';

    final assistantMessage = ChatMessage(
      id: assistantMessageId,
      sessionId: sessionId,
      role: 'assistant',
      content: '',
      timestamp: DateTime.now(),
    );

    messages.add(assistantMessage);

    try {
      final List<ChatMessage> apiMessages = [];
      if (_systemPrompt != null && _systemPrompt!.trim().isNotEmpty) {
        apiMessages.add(ChatMessage(
          id: 'system',
          sessionId: sessionId,
          role: 'system',
          content: _systemPrompt!,
          timestamp: DateTime.now(),
        ));
      }

      apiMessages.addAll(messages.where((m) => m.id != assistantMessageId));

      final model = _selectedModelId!;
      final stream = _apiService.chatCompletionStream(
        apiKey: _apiKey!,
        model: model,
        messages: apiMessages,
        onUsage: (usage) {
          unawaited(_dbService.insertUsage(UsageRecord(
            id: const Uuid().v4(),
            model: model,
            cost: usage.cost,
            promptTokens: usage.promptTokens,
            completionTokens: usage.completionTokens,
            timestamp: DateTime.now(),
          )));
        },
      );

      await for (final chunk in stream) {
        assistantContent += chunk;
        final index = messages.indexWhere((m) => m.id == assistantMessageId);
        if (index != -1) {
          messages[index] = messages[index].copyWith(content: assistantContent);
          notifyListeners();
        }
      }

      final finalIndex = messages.indexWhere((m) => m.id == assistantMessageId);
      if (finalIndex != -1 && _sessionMessages.containsKey(sessionId)) {
        await _dbService.insertMessage(messages[finalIndex]);
      }

      unawaited(refreshBalance().catchError((_) {}));
    } catch (e) {
      _error = 'AI response error: $e';
      messages.removeWhere((m) => m.id == assistantMessageId);
    } finally {
      _streamingSessionIds.remove(sessionId);
      notifyListeners();
    }
  }

  Future<void> deleteSession(String sessionId) async {
    await _dbService.deleteSession(sessionId);
    _sessions = await _dbService.getSessions();
    _sessionMessages.remove(sessionId);
    if (_currentSession?.id == sessionId) {
      _currentSession = null;
    }
    notifyListeners();
  }

  Future<void> renameSession(String sessionId, String newTitle) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return;
    await _upsertSession(_sessions[sessionIndex].copyWith(title: newTitle));
    notifyListeners();
  }
}
