import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_tip_provider.dart';
import '../models/health_tip.dart';
import 'custom_cards.dart';

class OptimizedHealthTipList extends StatelessWidget {
  final Function(HealthTip) onTap;
  final VoidCallback onRetry;

  const OptimizedHealthTipList({
    super.key,
    required this.onTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<HealthTipProvider, HealthTipListData>(
      selector: (_, provider) => HealthTipListData(
        healthTips: provider.healthTips,
        isLoading: provider.isLoading,
        error: provider.error,
      ),
      builder: (context, data, child) {
        if (data.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (data.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading health tips',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  data.error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (data.healthTips.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.health_and_safety, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No health tips found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Check back later for health insights',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.healthTips.length,
          itemBuilder: (context, index) {
            final tip = data.healthTips[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HealthTipCard(
                title: tip.title,
                category: tip.category,
                readingTime: tip.readingTime,
                tags: tip.tags,
                onTap: () => onTap(tip),
              ),
            );
          },
        );
      },
    );
  }
}

class HealthTipListData {
  final List<HealthTip> healthTips;
  final bool isLoading;
  final String? error;

  HealthTipListData({
    required this.healthTips,
    required this.isLoading,
    this.error,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthTipListData &&
          runtimeType == other.runtimeType &&
          healthTips.length == other.healthTips.length &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode => healthTips.length.hashCode ^ isLoading.hashCode ^ error.hashCode;
}
