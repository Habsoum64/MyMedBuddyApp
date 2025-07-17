import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_tip_provider.dart';
import '../widgets/custom_cards.dart';
import '../models/health_tip.dart';

class HealthTipsScreen extends StatefulWidget {
  const HealthTipsScreen({super.key});

  @override
  State<HealthTipsScreen> createState() => _HealthTipsScreenState();
}

class _HealthTipsScreenState extends State<HealthTipsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and filter
        Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    context.read<HealthTipProvider>().setSearchQuery(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search health tips...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Colors.grey[100],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilters,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[850]
                      : Colors.grey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Categories section
        _buildCategoriesSection(),
        
        // Health tips list
        Expanded(
          child: Consumer<HealthTipProvider>(
            builder: (context, healthTipProvider, child) {
              if (healthTipProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (healthTipProvider.error != null) {
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
                        healthTipProvider.error!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => healthTipProvider.loadHealthTips(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final healthTips = healthTipProvider.healthTips;
              
              if (healthTips.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.health_and_safety, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No health tips found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text('Try adjusting your search or filters'),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await healthTipProvider.loadHealthTips();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: healthTips.length,
                  itemBuilder: (context, index) {
                    final healthTip = healthTips[index];
                    
                    return HealthTipCard(
                      title: healthTip.title,
                      category: healthTip.category,
                      readingTime: healthTip.readingTime,
                      tags: healthTip.tags,
                      onTap: () => _showHealthTipDetail(healthTip),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Consumer<HealthTipProvider>(
      builder: (context, healthTipProvider, child) {
        final categories = healthTipProvider.categories;
        
        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 60,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length + 1, // +1 for "All" option
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = healthTipProvider.categoryFilter.isEmpty;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        healthTipProvider.setCategoryFilter('');
                      }
                    },
                    selectedColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.teal.shade300.withOpacity(0.3)
                        : Theme.of(context).primaryColor.withOpacity(0.2),
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[850]
                        : Colors.grey[50],
                    checkmarkColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.teal.shade300
                        : Theme.of(context).primaryColor,
                  ),
                );
              }
              
              final category = categories[index - 1];
              final isSelected = healthTipProvider.categoryFilter == category;
              
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    healthTipProvider.setCategoryFilter(selected ? category : '');
                  },
                  selectedColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.teal.shade300.withOpacity(0.3)
                      : Theme.of(context).primaryColor.withOpacity(0.2),
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[850]
                      : Colors.grey[50],
                  checkmarkColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.teal.shade300
                      : Theme.of(context).primaryColor,
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showFilters() {
    final healthTipProvider = context.read<HealthTipProvider>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Health Tips'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Category'),
              value: healthTipProvider.categoryFilter.isEmpty 
                ? null 
                : healthTipProvider.categoryFilter,
              items: ['', ...healthTipProvider.categories].map((category) {
                return DropdownMenuItem<String>(
                  value: category.isEmpty ? null : category,
                  child: Text(category.isEmpty ? 'All Categories' : category),
                );
              }).toList(),
              onChanged: (value) => healthTipProvider.setCategoryFilter(value ?? ''),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Sort By'),
              value: healthTipProvider.sortBy,
              items: const ['date', 'title', 'readingTime'].map((sort) {
                String displayText = sort;
                switch (sort) {
                  case 'date':
                    displayText = 'Date';
                    break;
                  case 'title':
                    displayText = 'Title';
                    break;
                  case 'readingTime':
                    displayText = 'Reading Time';
                    break;
                }
                return DropdownMenuItem<String>(
                  value: sort,
                  child: Text(displayText),
                );
              }).toList(),
              onChanged: (value) => healthTipProvider.setSortBy(value ?? 'date'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              healthTipProvider.clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showHealthTipDetail(HealthTip healthTip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthTipDetailScreen(healthTip: healthTip),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class HealthTipDetailScreen extends StatelessWidget {
  final HealthTip healthTip;

  const HealthTipDetailScreen({
    super.key,
    required this.healthTip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Tip'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareHealthTip(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    healthTip.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          healthTip.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${healthTip.readingTime} min read',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (healthTip.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: healthTip.tags.map((tag) => Chip(
                        label: Text(
                          tag,
                          style: const TextStyle(fontSize: 11),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Content
            Text(
              healthTip.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
                fontSize: 16,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Related tips
            _buildRelatedTips(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedTips(BuildContext context) {
    return Consumer<HealthTipProvider>(
      builder: (context, healthTipProvider, child) {
        final relatedTips = healthTipProvider.getRelatedTips(healthTip.id);
        
        if (relatedTips.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Related Tips',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...relatedTips.map((tip) => HealthTipCard(
              title: tip.title,
              category: tip.category,
              readingTime: tip.readingTime,
              tags: tip.tags,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HealthTipDetailScreen(healthTip: tip),
                  ),
                );
              },
            )),
          ],
        );
      },
    );
  }

  void _shareHealthTip() {
    // TODO: Implement share functionality
    // For now, just show a snackbar
  }
}
