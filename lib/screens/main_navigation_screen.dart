import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/health_tip_provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_navigation.dart';
import '../widgets/medication_selection_form.dart';
import '../models/appointment.dart';
import 'dashboard_screen.dart';
import 'medications_screen.dart';
import 'appointments_screen.dart';
import 'health_tips_screen.dart';
import 'profile_screen.dart';
import 'logs_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'advanced_health_logs_screen.dart';
import 'login_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const DashboardScreen(),
    const MedicationsScreen(),
    const AppointmentsScreen(),
    const HealthTipsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Defer loading data until after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    // Load data for all providers
    final medicationProvider = context.read<MedicationProvider>();
    final appointmentProvider = context.read<AppointmentProvider>();
    final healthTipProvider = context.read<HealthTipProvider>();

    await Future.wait([
      medicationProvider.loadMedications(),
      medicationProvider.loadMedicationLogs(),
      appointmentProvider.loadAppointments(),
      healthTipProvider.loadHealthTips(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Scaffold(
          key: _scaffoldKey,
          appBar: CustomAppBar(
            title: navigationProvider.currentPageTitle,
            onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
            actions: _buildAppBarActions(navigationProvider.currentIndex),
          ),
          drawer: CustomDrawer(
            onProfileTap: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            onLogsTap: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LogsScreen()),
              );
            },
            onAdvancedLogsTap: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdvancedHealthLogsScreen()),
              );
            },
            onReportTap: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsScreen()),
              );
            },
            onSettingsTap: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            onHelpTap: () {
              Navigator.of(context).pop();
              _showHelpDialog();
            },
            onLogoutTap: () {
              Navigator.of(context).pop();
              _handleLogout();
            },
          ),
          body: IndexedStack(
            index: navigationProvider.currentIndex,
            children: _screens,
          ),
          floatingActionButton: navigationProvider.currentIndex == 1
              ? FloatingActionButton(
                  onPressed: _showAddMedicationDialog,
                  tooltip: 'Add Medication',
                  child: const Icon(Icons.add),
                )
              : null,
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: navigationProvider.currentIndex,
            onTap: navigationProvider.setCurrentIndex,
          ),
        );
      },
    );
  }

  List<Widget>? _buildAppBarActions(int currentIndex) {
    List<Widget> actions = [];

    // Add theme toggle button
    actions.add(
      Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
          );
        },
      ),
    );

    // Add filter button for specific screens
    switch (currentIndex) {
      case 1: // Medications
      case 2: // Appointments
      case 3: // Health Tips
        actions.add(
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
        );
        break;
    }

    return actions.isNotEmpty ? actions : null;
  }

  void _showFilterOptions() {
    final navigationProvider = context.read<NavigationProvider>();
    
    switch (navigationProvider.currentIndex) {
      case 1: // Medications
        _showMedicationFilters();
        break;
      case 2: // Appointments
        _showAppointmentFilters();
        break;
      case 3: // Health Tips
        _showHealthTipFilters();
        break;
    }
  }

  void _showMedicationFilters() {
    final medicationProvider = context.read<MedicationProvider>();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => FilterBottomSheet(
        selectedCategory: medicationProvider.categoryFilter.isEmpty 
          ? null 
          : medicationProvider.categoryFilter,
        selectedStatus: medicationProvider.statusFilter.isEmpty 
          ? null 
          : medicationProvider.statusFilter,
        selectedSort: medicationProvider.sortBy,
        categories: medicationProvider.categories,
        statusOptions: const ['active', 'inactive', 'expired'],
        sortOptions: const ['name', 'date', 'category'],
        onCategoryChanged: (category) => medicationProvider.setCategoryFilter(category ?? ''),
        onStatusChanged: (status) => medicationProvider.setStatusFilter(status ?? ''),
        onSortChanged: (sort) => medicationProvider.setSortBy(sort ?? 'name'),
        onClearFilters: medicationProvider.clearFilters,
        onApplyFilters: () => Navigator.pop(context),
      ),
    );
  }

  void _showAppointmentFilters() {
    final appointmentProvider = context.read<AppointmentProvider>();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => FilterBottomSheet(
        selectedCategory: appointmentProvider.typeFilter.isEmpty 
          ? null 
          : appointmentProvider.typeFilter,
        selectedStatus: appointmentProvider.statusFilter?.toString().split('.').last,
        selectedSort: appointmentProvider.sortBy,
        categories: appointmentProvider.appointmentTypes,
        statusOptions: const ['scheduled', 'completed', 'cancelled', 'missed'],
        sortOptions: const ['date', 'doctor', 'type'],
        onCategoryChanged: (type) => appointmentProvider.setTypeFilter(type ?? ''),
        onStatusChanged: (status) {
          if (status == null) {
            appointmentProvider.setStatusFilter(null);
          } else {
            final statusEnum = AppointmentStatus.values.firstWhere(
              (e) => e.toString().split('.').last == status,
            );
            appointmentProvider.setStatusFilter(statusEnum);
          }
        },
        onSortChanged: (sort) => appointmentProvider.setSortBy(sort ?? 'date'),
        onClearFilters: appointmentProvider.clearFilters,
        onApplyFilters: () => Navigator.pop(context),
      ),
    );
  }

  void _showHealthTipFilters() {
    final healthTipProvider = context.read<HealthTipProvider>();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => FilterBottomSheet(
        selectedCategory: healthTipProvider.categoryFilter.isEmpty 
          ? null 
          : healthTipProvider.categoryFilter,
        selectedSort: healthTipProvider.sortBy,
        categories: healthTipProvider.categories,
        statusOptions: const [],
        sortOptions: const ['date', 'title', 'readingTime'],
        onCategoryChanged: (category) => healthTipProvider.setCategoryFilter(category ?? ''),
        onStatusChanged: (status) {}, // Not used for health tips
        onSortChanged: (sort) => healthTipProvider.setSortBy(sort ?? 'date'),
        onClearFilters: healthTipProvider.clearFilters,
        onApplyFilters: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        // Logout using AuthService
        final authService = AuthService();
        await authService.logout();

        // Navigate to login screen and remove all previous routes
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        // Show error if logout fails
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error during logout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAddMedicationDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Medication',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: MedicationSelectionForm(
                    onSave: (medication, catalogId) {
                      context.read<MedicationProvider>().addMedication(medication, catalogId);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Medication added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MyMedBuddy - Your Health Companion'),
            SizedBox(height: 16),
            Text('Features:'),
            Text('• Medication reminders and tracking'),
            Text('• Appointment management'),
            Text('• Health tips and articles'),
            Text('• Medication logs and reports'),
            SizedBox(height: 16),
            Text('For support, contact: support@mymedbuddy.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
