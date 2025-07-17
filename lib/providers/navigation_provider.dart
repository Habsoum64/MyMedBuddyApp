import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  bool _isSidebarOpen = false;

  int get currentIndex => _currentIndex;
  bool get isSidebarOpen => _isSidebarOpen;

  String get currentPageTitle {
    switch (_currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Medications';
      case 2:
        return 'Appointments';
      case 3:
        return 'Health Tips';
      default:
        return 'MyMedBuddy';
    }
  }

  IconData get currentPageIcon {
    switch (_currentIndex) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.medication;
      case 2:
        return Icons.calendar_today;
      case 3:
        return Icons.health_and_safety;
      default:
        return Icons.home;
    }
  }

  void setCurrentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void toggleSidebar() {
    _isSidebarOpen = !_isSidebarOpen;
    notifyListeners();
  }

  void closeSidebar() {
    if (_isSidebarOpen) {
      _isSidebarOpen = false;
      notifyListeners();
    }
  }

  void openSidebar() {
    if (!_isSidebarOpen) {
      _isSidebarOpen = true;
      notifyListeners();
    }
  }
}
