import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/usage_stats.dart';
import '../providers/chat_provider.dart';
import '../utils/ui_utils.dart';

class UsageScreen extends StatefulWidget {
  const UsageScreen({super.key});

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  late Future<UsageStats> _statsFuture;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _statsFuture = context.read<ChatProvider>().getUsageStats();
  }

  Future<void> _refresh() async {
    final provider = context.read<ChatProvider>();
    setState(() {
      _isRefreshing = true;
      _statsFuture = provider.getUsageStats();
    });
    try {
      await provider.refreshBalance();
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Balance refresh failed: $e');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usage & Balance')),
      body: FutureBuilder<UsageStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load usage: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
              children: [
                _buildBalanceCard(context),
                const SizedBox(height: 16),
                _buildTokensCard(context, stats),
                const SizedBox(height: 16),
                _buildTopModelsCard(context, stats),
                const SizedBox(height: 12),
                Text(
                  'Balance and spend come from OpenRouter for this API key '
                  '(all apps included). OpenRouter does not expose token or '
                  'per-model history to regular keys, so those cards reflect '
                  'chats made from this app only.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final balance = provider.balance;
    final updatedAt = provider.balanceUpdatedAt;
    final balanceStr = balance != null ? formatCost(balance) : '—';
    // Spend figures come from OpenRouter only — never from local records.
    final keyUsage = provider.keyUsage;
    String serverCost(double? value) => value != null ? formatCost(value) : '—';

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OpenRouter',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              OutlinedButton.icon(
                onPressed: _isRefreshing ? null : _refresh,
                icon: _isRefreshing
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                updatedAt != null
                    ? 'Updated ${formatRelativeTime(updatedAt)}'
                    : 'Balance not fetched yet',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              Text(
                'Balance: $balanceStr',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(child: _stat('Balance', balanceStr)),
              Expanded(child: _stat('Today', serverCost(keyUsage?.usageDaily))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _stat('Week', serverCost(keyUsage?.usageWeekly))),
              Expanded(
                  child: _stat('Month', serverCost(keyUsage?.usageMonthly))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTokensCard(BuildContext context, UsageStats stats) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tokens · this app',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(child: _stat('Total', formatTokens(stats.totalTokens))),
              Expanded(child: _stat('Requests', '${stats.totalRequests}')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _stat('Prompt', formatTokens(stats.promptTokens))),
              Expanded(
                  child:
                      _stat('Completion', formatTokens(stats.completionTokens))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopModelsCard(BuildContext context, UsageStats stats) {
    final provider = context.read<ChatProvider>();

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Models · this app',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          if (stats.topModels.isEmpty)
            Text(
              'No usage recorded yet. Stats appear here after your next chat.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            )
          else
            ...stats.topModels.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.modelDisplayName(m.model),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${m.requests} request${m.requests == 1 ? '' : 's'}'
                              ' · ${formatTokens(m.totalTokens)} tokens',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatCost(m.cost),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
