import 'package:flutter/material.dart';
import '../models/health_tip.dart';
import '../services/database_service.dart';

class HealthTipProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<HealthTip> _healthTips = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String? _error;
  bool _hasLoadedTips = false;

  // Filters
  String _searchQuery = '';
  String _categoryFilter = '';
  String _sortBy = 'date'; // date, title, readingTime

  List<HealthTip> get healthTips {
    // Auto-load health tips if not already loaded
    if (!_hasLoadedTips && !_isLoading) {
      // Use Future.microtask to avoid calling notifyListeners during build
      Future.microtask(() => loadHealthTips());
    }
    return _filteredHealthTips;
  }
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get categoryFilter => _categoryFilter;
  String get sortBy => _sortBy;

  List<HealthTip> get _filteredHealthTips {
    var filtered = List<HealthTip>.from(_healthTips);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((tip) =>
        tip.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        tip.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        tip.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }

    // Apply category filter
    if (_categoryFilter.isNotEmpty) {
      filtered = filtered.where((tip) => tip.category == _categoryFilter).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'date':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'title':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'readingTime':
        filtered.sort((a, b) => a.readingTime.compareTo(b.readingTime));
        break;
    }

    return filtered;
  }

  List<HealthTip> get featuredTips {
    // Return recent tips (last 7 days) or latest 3 tips
    final recentDate = DateTime.now().subtract(const Duration(days: 7));
    var recent = _healthTips.where((tip) => tip.createdAt.isAfter(recentDate)).toList();
    
    if (recent.isEmpty) {
      recent = _healthTips.take(3).toList();
    }
    
    return recent..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<HealthTip> getHealthTipsByCategory(String category) {
    return _healthTips.where((tip) => tip.category == category).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> loadHealthTips() async {
    if (_hasLoadedTips) return;
    
    _setLoading(true);
    try {
      // Health tips don't require authentication - they're available to all users
      // Load from database
      final dbResults = await _databaseService.getAllHealthTips();
      
      // Convert database results to HealthTip objects
      _healthTips = dbResults.map((data) {
        return HealthTip(
          id: data['id'] as String,
          title: data['title'] as String,
          content: data['content'] as String,
          category: data['category'] as String,
          tags: (data['tags'] as String?)?.split(',').map((e) => e.trim()).toList() ?? [],
          createdAt: DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now(),
          readingTime: _calculateReadingTime(data['content'] as String),
          imageUrl: null, // Can be added to database later
        );
      }).toList();

      // Extract categories from health tips
      _categories = _healthTips.map((tip) => tip.category).toSet().toList()..sort();

      _error = null;
      _hasLoadedTips = true;
    } catch (e) {
      _error = e.toString();
      _healthTips = [];
      _categories = [];
      _hasLoadedTips = true; // Mark as loaded even if error to prevent infinite retries
    } finally {
      _setLoading(false);
    }
  }

  // Method to refresh health tips (force reload)
  Future<void> refreshHealthTips() async {
    _hasLoadedTips = false;
    await loadHealthTips();
  }

  int _calculateReadingTime(String content) {
    // Estimate reading time based on average reading speed (200 words per minute)
    final wordCount = content.split(RegExp(r'\s+')).length;
    return (wordCount / 200).ceil();
  }

  // Search health tips from database
  Future<List<HealthTip>> searchHealthTips(String query) async {
    try {
      if (query.isEmpty) {
        return _healthTips;
      }
      
      // Search in database
      final dbResults = await _databaseService.searchHealthTips(query);
      
      // Convert database results to HealthTip objects
      return dbResults.map((data) {
        return HealthTip(
          id: data['id'] as String,
          title: data['title'] as String,
          content: data['content'] as String,
          category: data['category'] as String,
          tags: (data['tags'] as String?)?.split(',').map((e) => e.trim()).toList() ?? [],
          createdAt: DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now(),
          readingTime: _calculateReadingTime(data['content'] as String),
          imageUrl: null,
        );
      }).toList();
    } catch (e) {
      // Error searching health tips
      return [];
    }
  }

  Future<void> loadHealthTipsByCategory(String category) async {
    _setLoading(true);
    try {
      // Load from database by category
      final dbResults = await _databaseService.getHealthTipsByCategory(category);
      
      // Convert database results to HealthTip objects
      _healthTips = dbResults.map((data) {
        return HealthTip(
          id: data['id'] as String,
          title: data['title'] as String,
          content: data['content'] as String,
          category: data['category'] as String,
          tags: (data['tags'] as String?)?.split(',').map((e) => e.trim()).toList() ?? [],
          createdAt: DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now(),
          readingTime: _calculateReadingTime(data['content'] as String),
          imageUrl: null,
        );
      }).toList();

      _error = null;
    } catch (e) {
      _error = e.toString();
      _healthTips = [];
    } finally {
      _setLoading(false);
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _categoryFilter = '';
    _sortBy = 'date';
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  HealthTip? getHealthTipById(String id) {
    try {
      return _healthTips.firstWhere((tip) => tip.id == id);
    } catch (e) {
      return null;
    }
  }

  List<HealthTip> getRelatedTips(String currentTipId, {int limit = 3}) {
    final currentTip = getHealthTipById(currentTipId);
    if (currentTip == null) return [];

    // Find tips with similar tags or same category
    final relatedTips = _healthTips.where((tip) {
      if (tip.id == currentTipId) return false;
      
      // Same category
      if (tip.category == currentTip.category) return true;
      
      // Similar tags
      return tip.tags.any((tag) => currentTip.tags.contains(tag));
    }).toList();

    // Sort by relevance (more matching tags = higher priority)
    relatedTips.sort((a, b) {
      final aMatches = a.tags.where((tag) => currentTip.tags.contains(tag)).length;
      final bMatches = b.tags.where((tag) => currentTip.tags.contains(tag)).length;
      return bMatches.compareTo(aMatches);
    });

    return relatedTips.take(limit).toList();
  }

  // Statistics
  int get totalTips => _healthTips.length;
  int get totalCategories => _categories.length;
  
  Map<String, int> get tipsByCategory {
    final Map<String, int> categoryCount = {};
    for (final tip in _healthTips) {
      categoryCount[tip.category] = (categoryCount[tip.category] ?? 0) + 1;
    }
    return categoryCount;
  }

  double get averageReadingTime {
    if (_healthTips.isEmpty) return 0.0;
    final totalTime = _healthTips.fold<int>(0, (sum, tip) => sum + tip.readingTime);
    return totalTime / _healthTips.length;
  }
}
