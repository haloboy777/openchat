import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final Function(String) onEdit;

  const MessageBubble({
    super.key,
    required this.message,
    required this.onEdit,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isEditing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.message.content);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == 'user';
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isUser) ...[
                Icon(Icons.auto_awesome, size: 14, color: theme.primaryColor),
                const SizedBox(width: 4),
              ],
              Text(
                isUser ? 'YOU' : 'AI',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 4),
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              ],
            ],
          ),
          const SizedBox(height: 6),
          _isEditing
              ? _buildEditMode(theme)
              : _buildMessageContent(theme, isUser),
        ],
      ),
    );
  }

  Widget _buildMessageContent(ThemeData theme, bool isUser) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
          decoration: BoxDecoration(
            color: isUser ? theme.primaryColor : (isDark ? Colors.grey[850] : Colors.grey[100]),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            boxShadow: [
              if (!isUser)
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: MarkdownBody(
            data: widget.message.content,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                color: isUser ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontSize: 15,
                height: 1.4,
              ),
              code: TextStyle(
                backgroundColor: isUser 
                  ? Colors.blue[900]?.withValues(alpha: 0.3)
                  : (isDark ? Colors.grey[800] : Colors.grey[200]),
                fontFamily: 'monospace',
                fontSize: 13,
                color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
              ),
              codeblockDecoration: BoxDecoration(
                color: isUser 
                  ? Colors.blue[900]?.withValues(alpha: 0.3)
                  : (isDark ? Colors.grey[800] : Colors.grey[200]),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        if (isUser && !_isEditing)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: InkWell(
              onTap: () => setState(() => _isEditing = true),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      'Edit',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEditMode(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _editController,
            maxLines: null,
            autofocus: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Edit message...',
            ),
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
            cursorColor: theme.primaryColor,
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _isEditing = false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_editController.text.trim().isNotEmpty) {
                    widget.onEdit(_editController.text.trim());
                  }
                  setState(() => _isEditing = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Save & Restart'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
