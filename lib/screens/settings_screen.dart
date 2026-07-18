import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../services/export_service.dart';
import 'profiles_screen.dart';
import 'provider_selection_screen.dart';
import 'usage_screen.dart';
import '../utils/ui_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;
  late ChatProvider _provider;
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ChatProvider>();
    _apiKeyController = TextEditingController(text: _provider.apiKey);
  }

  @override
  void dispose() {
    // Flush a pending save so backing out right after a paste still saves.
    if (_saveDebounce?.isActive ?? false) {
      _saveDebounce!.cancel();
      _saveApiKey(showFeedback: false);
    }
    _apiKeyController.dispose();
    super.dispose();
  }

  void _onApiKeyChanged(String _) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 800), _saveApiKey);
  }

  Future<void> _saveApiKey({bool showFeedback = true}) async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty || key == _provider.apiKey) return;
    try {
      await _provider.setApiKey(key);
      if (showFeedback && mounted) {
        showSuccessSnackbar(context, 'API key saved');
      }
    } catch (e) {
      if (showFeedback && mounted) {
        showErrorSnackbar(context, 'API key save failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          final lastFetch = provider.lastModelsFetch;
          final fetchStr = lastFetch != null 
              ? DateFormat('MMM d, HH:mm').format(lastFetch) 
              : 'Never';

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16, 
              16, 
              16, 
              MediaQuery.of(context).padding.bottom + 16
            ),
            children: [
              _buildSectionTitle('API Configuration'),
              const SizedBox(height: 8),
              TextField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'OpenRouter API Key',
                  hintText: 'sk-or-v1-...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                  helperText: 'Saved automatically',
                ),
                obscureText: true,
                onChanged: _onApiKeyChanged,
                onSubmitted: (_) {
                  _saveDebounce?.cancel();
                  _saveApiKey();
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Model List Cache', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('Last updated: $fetchStr', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await provider.fetchModels(forceRefresh: true);
                        if (context.mounted) showSuccessSnackbar(context, 'Model list updated');
                      } catch (e) {
                        if (context.mounted) showErrorSnackbar(context, 'Refresh failed: $e');
                      }
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Filter Providers'),
                subtitle: Text(
                  provider.selectedProviders == null
                    ? 'All providers selected' 
                    : '${provider.selectedProviders!.length} providers selected',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProviderSelectionScreen()),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Usage & Balance'),
                subtitle: Text(
                  provider.balance != null
                      ? 'Balance: ${formatCost(provider.balance!)}'
                      : 'Spending, tokens, and top models',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UsageScreen()),
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('AI Behavior'),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('System Prompt Profiles'),
                subtitle: Text(
                  provider.activeProfile != null
                      ? 'Active: ${provider.activeProfile!.name}'
                      : 'No active profile',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilesScreen()),
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Data'),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Export Chats'),
                subtitle: const Text(
                  'Back up as SQLite database or JSON',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.ios_share),
                onTap: () => _showExportDialog(context),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Appearance'),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                  ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.settings_brightness)),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                ],
                selected: {provider.themeMode},
                onSelectionChanged: (Set<ThemeMode> newSelection) {
                  provider.setThemeMode(newSelection.first);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    final exportService = ExportService();

    Future<void> run(Future<void> Function() export) async {
      try {
        await export();
      } catch (e) {
        if (context.mounted) showErrorSnackbar(context, 'Export failed: $e');
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Export Chats'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: [
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('SQLite database'),
            subtitle: const Text('Complete backup file (.db)',
                style: TextStyle(fontSize: 12)),
            onTap: () {
              Navigator.pop(dialogContext);
              run(exportService.exportDatabase);
            },
          ),
          ListTile(
            leading: const Icon(Icons.data_object),
            title: const Text('JSON'),
            subtitle: const Text('Readable export of all chats (.json)',
                style: TextStyle(fontSize: 12)),
            onTap: () {
              Navigator.pop(dialogContext);
              run(exportService.exportJson);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
        color: Colors.blue,
      ),
    );
  }
}
