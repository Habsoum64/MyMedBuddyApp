import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedIconTheme: theme.bottomNavigationBarTheme.selectedIconTheme,
        unselectedIconTheme: theme.bottomNavigationBarTheme.unselectedIconTheme,
        selectedLabelStyle: theme.bottomNavigationBarTheme.selectedLabelStyle,
        unselectedLabelStyle: theme.bottomNavigationBarTheme.unselectedLabelStyle,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_outlined),
            activeIcon: Icon(Icons.medication),
            label: 'Medications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety_outlined),
            activeIcon: Icon(Icons.health_and_safety),
            label: 'Health Tips',
          ),
        ],
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuPressed;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onMenuPressed,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: theme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : onMenuPressed != null
              ? IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: onMenuPressed,
                )
              : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CustomDrawer extends StatelessWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogsTap;
  final VoidCallback? onAdvancedLogsTap;
  final VoidCallback? onReportTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onHelpTap;
  final VoidCallback? onLogoutTap;

  const CustomDrawer({
    super.key,
    this.onProfileTap,
    this.onLogsTap,
    this.onAdvancedLogsTap,
    this.onReportTap,
    this.onSettingsTap,
    this.onHelpTap,
    this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'MyMedBuddy',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your Health Companion',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerTile(
                  icon: Icons.person,
                  title: 'Profile',
                  onTap: onProfileTap,
                ),
                _DrawerTile(
                  icon: Icons.history,
                  title: 'Medication Logs',
                  onTap: onLogsTap,
                ),
                _DrawerTile(
                  icon: Icons.filter_list,
                  title: 'Advanced Health Logs',
                  onTap: onAdvancedLogsTap,
                ),
                _DrawerTile(
                  icon: Icons.assessment,
                  title: 'Health Reports',
                  onTap: onReportTap,
                ),
                const Divider(),
                _DrawerTile(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: onSettingsTap,
                ),
                _DrawerTile(
                  icon: Icons.help,
                  title: 'Help & Support',
                  onTap: onHelpTap,
                ),
                const Divider(),
                _DrawerTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: onLogoutTap,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Version 1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}

class FilterBottomSheet extends StatelessWidget {
  final String? selectedCategory;
  final String? selectedStatus;
  final String? selectedSort;
  final List<String> categories;
  final List<String> statusOptions;
  final List<String> sortOptions;
  final Function(String?) onCategoryChanged;
  final Function(String?) onStatusChanged;
  final Function(String?) onSortChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onApplyFilters;

  const FilterBottomSheet({
    super.key,
    this.selectedCategory,
    this.selectedStatus,
    this.selectedSort,
    required this.categories,
    required this.statusOptions,
    required this.sortOptions,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onSortChanged,
    required this.onClearFilters,
    required this.onApplyFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filter Options',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onClearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (categories.isNotEmpty) ...[
            Text(
              'Category',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: categories.map((category) => FilterChip(
                label: Text(category),
                selected: selectedCategory == category,
                onSelected: (selected) => onCategoryChanged(selected ? category : null),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (statusOptions.isNotEmpty) ...[
            Text(
              'Status',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: statusOptions.map((status) => FilterChip(
                label: Text(status),
                selected: selectedStatus == status,
                onSelected: (selected) => onStatusChanged(selected ? status : null),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Sort By',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: sortOptions.map((sort) => FilterChip(
              label: Text(sort),
              selected: selectedSort == sort,
              onSelected: (selected) => onSortChanged(selected ? sort : null),
            )).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onApplyFilters,
              child: const Text('Apply Filters'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class SearchBar extends StatelessWidget {
  final String hintText;
  final Function(String) onChanged;
  final VoidCallback? onFilterPressed;
  final TextEditingController? controller;

  const SearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.onFilterPressed,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          if (onFilterPressed != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: onFilterPressed,
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
