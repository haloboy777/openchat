import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../models/chat_session.dart';
import '../utils/ui_utils.dart';

class ChatDrawer extends StatelessWidget {
  const ChatDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF171717) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Consumer<ChatProvider>(
              builder: (context, provider, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        if (provider.messages.isNotEmpty) {
                          try {
                            await provider.createNewSession();
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) showErrorSnackbar(context, 'Failed to create session: $e');
                          }
                        } else {
                          // If current session is empty, just close drawer
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Chat'),
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
                        foregroundColor: isDark ? Colors.white : Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                        ),
                        alignment: Alignment.centerLeft,
                        elevation: 0,
                      ),
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, provider, child) {
                  if (provider.sessions.isEmpty) {
                    return Center(
                      child: Text(
                        'No history yet',
                        style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: provider.sessions.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final session = provider.sessions[index];
                      final isSelected = provider.currentSession?.id == session.id;
                      
                      return _ChatSessionItem(
                        session: session,
                        isSelected: isSelected,
                        isDark: isDark,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatSessionItem extends StatelessWidget {
  final ChatSession session;
  final bool isSelected;
  final bool isDark;

  const _ChatSessionItem({
    required this.session,
    required this.isSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<ChatProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          tileColor: isSelected 
            ? (isDark ? Colors.grey[900] : theme.primaryColor.withValues(alpha: 0.1))
            : Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          title: Text(
            session.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected 
                ? (isDark ? Colors.white : theme.primaryColor) 
                : (isDark ? Colors.grey[400] : Colors.black87),
              fontSize: 14,
            ),
          ),
          subtitle: Row(
            children: [
              Text(
                DateFormat('MMM d').format(session.lastUpdated),
                style: TextStyle(
                  fontSize: 10, 
                  color: isDark ? Colors.grey[600] : Colors.grey[500]
                ),
              ),
              if (provider.isSessionStreaming(session.id)) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 8,
                  height: 8,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ],
          ),
          onTap: () {
            provider.switchSession(session);
            Navigator.pop(context);
          },
          onLongPress: () => _showOptions(context, provider),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, ChatProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, ChatProvider provider) {
    final controller = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Chat'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  await provider.renameSession(session.id, controller.text.trim());
                } catch (e) {
                  if (context.mounted) showErrorSnackbar(context, 'Rename failed: $e');
                }
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ChatProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Text('This will permanently remove this conversation history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await provider.deleteSession(session.id);
              } catch (e) {
                if (context.mounted) showErrorSnackbar(context, 'Delete failed: $e');
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
