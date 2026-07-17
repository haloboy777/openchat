import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class ModelSelector extends StatelessWidget {
  final bool compact;
  
  const ModelSelector({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        if (provider.models.isEmpty) {
          return Center(
            child: SizedBox(
              height: 12,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: compact ? Colors.white : Theme.of(context).primaryColor,
              ),
            ),
          );
        }

        // Ensure the value is in the items list to prevent assertion crash
        final dropdownValue = provider.models.any((m) => m.id == provider.selectedModelId)
            ? provider.selectedModelId
            : provider.models.first.id;

        return DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: dropdownValue,
            onChanged: (String? newValue) {
              if (newValue != null) {
                provider.setSelectedModel(newValue);
              }
            },
            alignment: Alignment.center,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: compact ? Colors.white : null,
              fontSize: 14,
            ),
            icon: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: compact ? Colors.white70 : Theme.of(context).primaryColor,
              ),
            ),
            selectedItemBuilder: (context) {
              return provider.models.map((m) {
                return Center(
                  child: Text(
                    m.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: compact ? Colors.white : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList();
            },
            items: provider.models.map((model) {
              return DropdownMenuItem<String>(
                value: model.id,
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 14,
                      color: isDark(context) ? Colors.blue[300] : Colors.blue,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        model.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark(context) ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
}
