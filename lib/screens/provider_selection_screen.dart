import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../utils/ui_utils.dart';

class ProviderSelectionScreen extends StatefulWidget {
  const ProviderSelectionScreen({super.key});

  @override
  State<ProviderSelectionScreen> createState() => _ProviderSelectionScreenState();
}

class _ProviderSelectionScreenState extends State<ProviderSelectionScreen> {
  late List<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ChatProvider>();
    final selected = provider.selectedProviders;
    if (selected == null) {
      _tempSelected = List.from(provider.availableProviders);
    } else {
      _tempSelected = List.from(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final allProviders = provider.availableProviders;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Providers'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _tempSelected = List.from(allProviders);
              });
            },
            child: const Text('All'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _tempSelected = [];
              });
            },
            child: const Text('None'),
          ),
        ],
      ),
      body: allProviders.isEmpty
          ? const Center(child: Text('No models loaded. Set API key first.'))
          : ListView.builder(
              itemCount: allProviders.length,
              itemBuilder: (context, index) {
                final p = allProviders[index];
                final isSelected = _tempSelected.contains(p);
                
                return CheckboxListTile(
                  title: Text(
                    p.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  value: isSelected,
                  activeColor: Colors.blue,
                  checkColor: Colors.white,
                  side: BorderSide(
                    color: theme.brightness == Brightness.dark 
                        ? Colors.white70 
                        : Colors.black54,
                    width: 1.5,
                  ),
                  checkboxShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _tempSelected.add(p);
                      } else {
                        _tempSelected.remove(p);
                      }
                    });
                  },
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
        child: FilledButton(
          onPressed: () async {
            if (_tempSelected.isEmpty) {
              showInfoSnackbar(context, 'Please select at least one provider');
              return;
            }
            try {
              if (_tempSelected.length == allProviders.length) {
                await provider.setProviders(null);
              } else {
                await provider.setProviders(_tempSelected);
              }
              if (context.mounted) Navigator.pop(context);
            } catch (e) {
              if (context.mounted) showErrorSnackbar(context, 'Apply failed: $e');
            }
          },
          child: const Text('Apply Filters'),
        ),
      ),
    );
  }
}
