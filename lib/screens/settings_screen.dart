import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../services/export_service.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _preferencesService = PreferencesService();
  final ExportService _exportService = ExportService();
  
  bool _medicationNotifications = true;
  bool _appointmentNotifications = true;
  bool _healthTipNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _medicationNotifications = _preferencesService.medicationNotifications;
      _appointmentNotifications = _preferencesService.appointmentNotifications;
      _healthTipNotifications = _preferencesService.healthTipNotifications;
      _soundEnabled = _preferencesService.soundEnabled;
      _vibrationEnabled = _preferencesService.vibrationEnabled;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _preferencesService.saveAllNotificationSettings({
      'medication': _medicationNotifications,
      'appointment': _appointmentNotifications,
      'healthTip': _healthTipNotifications,
      'sound': _soundEnabled,
      'vibration': _vibrationEnabled,
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Notification Settings'),
            _buildSettingsCard([
              _buildSwitchTile(
                title: 'Medication Reminders',
                subtitle: 'Get notified when it\'s time to take your medication',
                value: _medicationNotifications,
                onChanged: (value) {
                  setState(() {
                    _medicationNotifications = value;
                  });
                },
              ),
              _buildSwitchTile(
                title: 'Appointment Reminders',
                subtitle: 'Get notified about upcoming appointments',
                value: _appointmentNotifications,
                onChanged: (value) {
                  setState(() {
                    _appointmentNotifications = value;
                  });
                },
              ),
              _buildSwitchTile(
                title: 'Health Tips',
                subtitle: 'Receive daily health tips and information',
                value: _healthTipNotifications,
                onChanged: (value) {
                  setState(() {
                    _healthTipNotifications = value;
                  });
                },
              ),
            ]),
            
            const SizedBox(height: 24),
            
            _buildSectionTitle('Notification Preferences'),
            _buildSettingsCard([
              _buildSwitchTile(
                title: 'Sound',
                subtitle: 'Play sound with notifications',
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() {
                    _soundEnabled = value;
                  });
                },
              ),
              _buildSwitchTile(
                title: 'Vibration',
                subtitle: 'Vibrate device for notifications',
                value: _vibrationEnabled,
                onChanged: (value) {
                  setState(() {
                    _vibrationEnabled = value;
                  });
                },
              ),
            ]),
            
            const SizedBox(height: 24),
            
            _buildSectionTitle('Appearance'),
            _buildSettingsCard([
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return _buildSwitchTile(
                    title: 'Dark Mode',
                    subtitle: 'Use dark theme for better viewing in low light',
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.setTheme(value);
                    },
                  );
                },
              ),
            ]),
            
            const SizedBox(height: 24),
            
            _buildSectionTitle('Privacy & Security'),
            _buildInfoCard([
              _buildInfoTile(
                icon: Icons.security,
                title: 'Data Security',
                subtitle: 'Your data is stored locally on your device',
              ),
              _buildInfoTile(
                icon: Icons.lock,
                title: 'Privacy Policy',
                subtitle: 'Learn about how we protect your information',
              ),
            ]),
            
            const SizedBox(height: 24),
            
            _buildSectionTitle('Data Management'),
            _buildActionCard([
              _buildActionTile(
                icon: Icons.backup,
                title: 'Export Data',
                subtitle: 'Export your medication and appointment data',
                onTap: _exportData,
              ),
              _buildActionTile(
                icon: Icons.delete_forever,
                title: 'Clear All Data',
                subtitle: 'Remove all stored data from the app',
                onTap: _showClearDataDialog,
                isDestructive: true,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildActionCard(List<Widget> children) {
    return Card(
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Export your health data and medication logs to PDF?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportToPDF();
            },
            child: const Text('Export to PDF'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPDF() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting to PDF...'),
            ],
          ),
        ),
      );

      // Export health report to PDF
      final healthReportPath = await _exportService.exportHealthReportToPDF();
      
      // Export medication logs to PDF
      final medicationLogsPath = await _exportService.exportMedicationLogsToPDF();

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Successful'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your data has been exported successfully to:'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Health Report:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(healthReportPath, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      const Text('Medication Logs:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(medicationLogsPath, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('You can find these files in your device\'s file manager.', 
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Failed'),
            content: Text('Failed to export data: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will permanently delete all your medications, appointments, and health data. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data clearing feature coming soon'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }
}
