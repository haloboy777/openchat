import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/system_prompt_profile.dart';
import '../providers/chat_provider.dart';
import '../utils/ui_utils.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final profiles = provider.profiles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Prompts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Profile',
            onPressed: () => _showProfileDialog(context),
          ),
        ],
      ),
      body: profiles.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.psychology_outlined,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No profiles yet',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a profile to give the AI a persona or standing '
                      'instructions, then switch between them per task.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _showProfileDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('New Profile'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(
                  12, 8, 12, MediaQuery.of(context).padding.bottom + 12),
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return _ProfileCard(
                  profile: profile,
                  isActive: profile.id == provider.activeProfileId,
                );
              },
            ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final SystemPromptProfile profile;
  final bool isActive;

  const _ProfileCard({required this.profile, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<ChatProvider>();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isActive
              ? theme.colorScheme.primary
              : theme.dividerColor.withValues(alpha: 0.4),
          width: isActive ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        // Tapping the active card again deactivates it (no system prompt).
        onTap: () => provider.setActiveProfile(isActive ? null : profile.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isActive) ...[
                          Icon(Icons.check_circle,
                              size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.greeting ?? profile.prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: profile.greeting != null
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: Colors.grey[600]),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showProfileDialog(context, existing: profile);
                  } else if (value == 'delete') {
                    _confirmDelete(context, provider);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ChatProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text('"${profile.name}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await provider.deleteProfile(profile.id);
              } catch (e) {
                if (context.mounted) {
                  showErrorSnackbar(context, 'Delete failed: $e');
                }
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Create (existing == null) or edit a profile.
void _showProfileDialog(BuildContext context, {SystemPromptProfile? existing}) {
  final provider = context.read<ChatProvider>();
  final nameController = TextEditingController(text: existing?.name);
  final promptController = TextEditingController(text: existing?.prompt);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(existing == null ? 'New Profile' : 'Edit Profile'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: existing == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Code Reviewer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: promptController,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'System Prompt',
                hintText: 'You are a meticulous senior engineer…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final name = nameController.text.trim();
            final prompt = promptController.text.trim();
            if (name.isEmpty || prompt.isEmpty) {
              showInfoSnackbar(context, 'Name and prompt are both required');
              return;
            }
            try {
              if (existing == null) {
                await provider.addProfile(name, prompt);
              } else {
                await provider
                    .updateProfile(existing.copyWith(name: name, prompt: prompt));
              }
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              if (context.mounted) showErrorSnackbar(context, 'Save failed: $e');
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
