import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return IconButton(
          icon: Icon(
            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: themeProvider.isDarkMode ? Colors.teal.shade300 : Colors.teal.shade600,
          ),
          onPressed: () {
            themeProvider.toggleTheme();
            
            // Show a brief snackbar to indicate theme change
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  themeProvider.isDarkMode 
                    ? 'Switched to Dark Mode' 
                    : 'Switched to Light Mode',
                ),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        );
      },
    );
  }
}

class ThemeToggleSwitch extends StatelessWidget {
  final String? label;
  final String? subtitle;
  
  const ThemeToggleSwitch({
    super.key,
    this.label,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return SwitchListTile(
          title: Text(label ?? 'Dark Mode'),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          value: themeProvider.isDarkMode,
          onChanged: (value) {
            themeProvider.setTheme(value);
          },
          secondary: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          ),
        );
      },
    );
  }
}
