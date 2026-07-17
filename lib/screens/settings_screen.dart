import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
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
  late TextEditingController _systemPromptController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ChatProvider>();
    _apiKeyController = TextEditingController(text: provider.apiKey);
    _systemPromptController = TextEditingController(text: provider.systemPrompt);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _systemPromptController.dispose();
    super.dispose();
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
                ),
                obscureText: true,
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
              TextField(
                controller: _systemPromptController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'System Prompt',
                  hintText: 'e.g., You are a helpful assistant who speaks like a pirate.',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
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
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isSaving ? null : () async {
                  setState(() => _isSaving = true);
                  try {
                    await provider.setApiKey(_apiKeyController.text);
                    await provider.setSystemPrompt(_systemPromptController.text);
                    if (context.mounted) showSuccessSnackbar(context, 'Settings saved successfully');
                  } catch (e) {
                    if (context.mounted) showErrorSnackbar(context, 'Save failed: $e');
                  } finally {
                    if (mounted) setState(() => _isSaving = false);
                  }
                },
                child: _isSaving 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save All Settings'),
              ),
            ],
          );
        },
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
