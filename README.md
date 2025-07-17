# MyMedBuddy

A comprehensive medication management and health tracking Flutter application designed to help users manage their medications, track health metrics, schedule appointments, and receive personalized health tips.

## 🚀 Features

### 📊 Dashboard
- Real-time medication status overview
- Upcoming appointments display
- Health metrics tracking
- Daily health tips
- Quick access to all major features

### 💊 Medication Management
- Add and edit medications with detailed information
- Medication catalog search with extensive database
- Automated medication scheduling and logging
- Overdue medication tracking
- Medication history and compliance reports
- Push notifications for medication reminders

### 📅 Appointments
- Schedule and manage medical appointments
- Appointment reminders and notifications
- Doctor and clinic information tracking
- Appointment history and notes

### 📈 Health Tracking
- Comprehensive health logs and metrics
- Visual charts and progress tracking
- Advanced filtering and search capabilities
- Health trend analysis

### 📋 Reports & Export
- Generate detailed medication reports
- Export health data to PDF
- Comprehensive health overview reports
- Appointment summaries

### 🔔 Notifications
- Medication reminder notifications
- Appointment alerts
- Customizable notification settings

### 🎨 User Experience
- Light and dark theme support
- Intuitive navigation with bottom navigation bar
- Responsive design for all screen sizes
- Clean, modern Material Design UI

## 🏗️ Architecture

The app follows a clean architecture pattern with clear separation of concerns:

### Directory Structure
```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── appointment.dart
│   ├── health_tip.dart
│   ├── medication.dart
│   ├── medication_log.dart
│   └── user_profile.dart
├── providers/                   # State management
│   ├── appointment_provider.dart
│   ├── health_filter_provider.dart
│   ├── health_tip_provider.dart
│   ├── medication_provider.dart
│   ├── navigation_provider.dart
│   └── theme_provider.dart
├── services/                    # Business logic and data services
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── database_service.dart
│   ├── export_service.dart
│   ├── firebase_service.dart
│   ├── notification_service.dart
│   └── preferences_service.dart
├── screens/                     # UI screens
│   ├── dashboard_screen.dart
│   ├── medications_screen.dart
│   ├── appointments_screen.dart
│   ├── health_tips_screen.dart
│   ├── logs_screen.dart
│   ├── reports_screen.dart
│   ├── login_screen.dart
│   └── settings_screen.dart
└── widgets/                     # Reusable UI components
    ├── custom_cards.dart
    ├── custom_forms.dart
    ├── custom_navigation.dart
    └── medication_selection_form.dart
```

### Architecture Patterns
- **Provider Pattern**: For state management across the app
- **Repository Pattern**: Data layer abstraction in services
- **Clean Architecture**: Separation of UI, business logic, and data layers
- **MVVM**: Model-View-ViewModel pattern implementation

## 📦 Dependencies

### Core Dependencies
- **flutter**: Flutter SDK
- **cupertino_icons**: iOS-style icons

### State Management
- **provider**: Primary state management solution
- **flutter_riverpod**: Additional state management for complex scenarios

### Data Storage
- **sqflite**: Local SQLite database
- **shared_preferences**: Simple key-value storage
- **path**: File system path manipulation

### Cloud Services
- **firebase_core**: Firebase initialization
- **cloud_firestore**: Cloud database for data sync

### UI & User Experience
- **intl**: Internationalization and date formatting
- **flutter_local_notifications**: Local push notifications

### File Operations
- **path_provider**: Access to file system directories
- **pdf**: PDF generation for reports
- **printing**: Print and share PDF documents

### Networking
- **http**: HTTP requests for API communication

## 🛠️ Installation and Setup

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK (included with Flutter)
- Android Studio or VS Code with Flutter extensions
- Android/iOS device or emulator

### Getting Started

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mymedbuddy_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase (Optional)**
   - Create a Firebase project at https://console.firebase.google.com
   - Add your Android/iOS app to the project
   - Download and place the configuration files:
     - `google-services.json` in `android/app/`
     - `GoogleService-Info.plist` in `ios/Runner/`

4. **Run the app**
   ```bash
   flutter run
   ```

### Development Setup

1. **Enable debugging**
   ```bash
   flutter run --debug
   ```

2. **Hot reload**
   - Press `r` in the terminal for hot reload
   - Press `R` for hot restart

3. **Build for release**
   ```bash
   flutter build apk                # Android APK
   flutter build ios                # iOS build
   flutter build appbundle          # Android App Bundle
   ```

## 🔧 Configuration

### Database Setup
The app uses SQLite for local storage with automatic database initialization. No manual setup required.

### Notification Setup
Notifications are automatically configured. Ensure the app has notification permissions on the device.

### Theme Configuration
The app supports light and dark themes that can be toggled in the settings screen.

## 🧪 Testing

### Running Tests
```bash
flutter test                      # Run all tests
flutter test test/unit/          # Run unit tests
flutter test test/widget/        # Run widget tests
```

### Test User Account
The app includes a test user feature for development and demonstration:
- Email: `test@mymedbuddy.com`
- Password: `TestUser123!`

This account comes with pre-populated sample data for testing purposes.

## 🚀 Deployment

### Android
1. Build release APK:
   ```bash
   flutter build apk --release
   ```

2. Build App Bundle for Play Store:
   ```bash
   flutter build appbundle --release
   ```

### iOS
1. Build for iOS:
   ```bash
   flutter build ios --release
   ```

2. Use Xcode for final app store deployment

## 📱 Platform Support

- ✅ Android (API 21+)
- ✅ iOS (13.0+)
- ✅ Web (Limited functionality)
- ✅ Windows (Desktop)
- ✅ macOS (Desktop)
- ✅ Linux (Desktop)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support, please create an issue in the repository or contact the development team.

## 🔄 Version History

### v1.0.0
- Initial release
- Core medication management features
- Appointment scheduling
- Health tracking
- PDF report generation
- Multi-theme support

---

**MyMedBuddy** - Your personal medication and health management companion.
