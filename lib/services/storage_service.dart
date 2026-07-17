import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _apiKey = 'open_router_api_key';
  static const _selectedModel = 'selected_model';
  static const _systemPrompt = 'system_prompt';
  static const _themeMode = 'theme_mode';
  static const _cachedModels = 'cached_models';
  static const _lastModelsFetch = 'last_models_fetch';
  static const _selectedProviders = 'selected_providers';
  static const _balance = 'balance';
  static const _balanceUpdatedAt = 'balance_updated_at';
  
  final _secureStorage = const FlutterSecureStorage();

  Future<void> saveApiKey(String key) async {
    await _secureStorage.write(key: _apiKey, value: key);
  }

  Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKey);
  }

  Future<void> saveSystemPrompt(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_systemPrompt, prompt);
  }

  Future<String?> getSystemPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_systemPrompt);
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeMode, mode);
  }

  Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeMode);
  }

  Future<void> saveSelectedModel(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedModel, modelId);
  }

  Future<String?> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedModel);
  }

  // Model Caching
  Future<void> saveCachedModels(String modelsJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedModels, modelsJson);
    await prefs.setString(_lastModelsFetch, DateTime.now().toIso8601String());
  }

  Future<String?> getCachedModels() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cachedModels);
  }

  Future<DateTime?> getLastModelsFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_lastModelsFetch);
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

  // Provider Selection
  Future<void> saveSelectedProviders(List<String>? providers) async {
    final prefs = await SharedPreferences.getInstance();
    if (providers == null) {
      await prefs.remove(_selectedProviders);
    } else {
      await prefs.setString(_selectedProviders, json.encode(providers));
    }
  }

  Future<List<String>?> getSelectedProviders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_selectedProviders);
    if (jsonStr == null) return null;
    return List<String>.from(json.decode(jsonStr));
  }

  // Balance
  Future<void> saveBalance(double balance, DateTime updatedAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_balance, balance);
    await prefs.setString(_balanceUpdatedAt, updatedAt.toIso8601String());
  }

  Future<double?> getBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_balance);
  }

  Future<DateTime?> getBalanceUpdatedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_balanceUpdatedAt);
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }
}
