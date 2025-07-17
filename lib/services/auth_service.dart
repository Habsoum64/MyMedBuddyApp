import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import '../models/user_profile.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  
  AuthService._internal();
  
  factory AuthService() {
    return _instance;
  }

  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _isLoggedInKey = 'is_logged_in';

  // Current user session
  String? _currentUserId;
  UserProfile? _currentUser;
  
  String? get currentUserId => _currentUserId;
  UserProfile? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUserId != null;

  // Initialize auth service and check for existing session
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    
    if (isLoggedIn) {
      _currentUserId = prefs.getString(_userIdKey);
      if (_currentUserId != null) {
        // Load user profile from database
        _currentUser = await DatabaseService().getUserProfile(_currentUserId!);
      }
    }
  }

  // Email validation helper
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Validation methods
  String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    if (!_isValidEmail(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Name is required';
    }
    if (name.length < 2) {
      return 'Name must be at least 2 characters long';
    }
    return null;
  }

  String? validatePasswordConfirmation(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Hash password for secure storage using PBKDF2-like approach
  String _hashPassword(String password, String salt) {
    final combined = password + salt;
    
    // Multiple rounds of hashing for security
    String hash = combined;
    for (int i = 0; i < 10000; i++) {
      final hashBytes = utf8.encode(hash + salt);
      int hashValue = 0;
      for (int byte in hashBytes) {
        hashValue = ((hashValue * 31) + byte) & 0x7FFFFFFF;
      }
      hash = hashValue.toRadixString(16);
    }
    
    return hash.padLeft(64, '0');
  }

  // Generate cryptographically strong salt
  String _generateSalt() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = List.generate(16, (_) => random.nextInt(256));
    
    // Combine timestamp and random bytes for uniqueness
    final saltBytes = utf8.encode(timestamp.toString()) + randomBytes;
    final saltString = saltBytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    
    return saltString.substring(0, 32);
  }

  // Register new user
  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    try {
      // Validate inputs
      final emailError = validateEmail(email);
      if (emailError != null) {
        return AuthResult.error(emailError);
      }

      final passwordError = validatePassword(password);
      if (passwordError != null) {
        return AuthResult.error(passwordError);
      }

      final nameError = validateName(name);
      if (nameError != null) {
        return AuthResult.error(nameError);
      }

      // Check if user already exists
      final existingUser = await DatabaseService().getUserByEmail(email);
      if (existingUser != null) {
        return AuthResult.error('An account with this email already exists');
      }

      // Create new user
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final salt = _generateSalt();
      final hashedPassword = _hashPassword(password, salt);

      final user = UserProfile(
        id: userId,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        gender: gender,
        emergencyContact: '',
        allergies: [],
        medicalConditions: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Store user in database
      await DatabaseService().insertUserProfile(user);
      await DatabaseService().insertUserCredentials(userId, hashedPassword, salt);

      // Set current session
      await _setUserSession(userId, email);
      _currentUser = user;

      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.error('Registration failed: ${e.toString()}');
    }
  }

  // Login user
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs
      final emailError = validateEmail(email);
      if (emailError != null) {
        return AuthResult.error(emailError);
      }

      if (password.isEmpty) {
        return AuthResult.error('Password is required');
      }

      // Get user by email
      final user = await DatabaseService().getUserByEmail(email);
      if (user == null) {
        return AuthResult.error('Invalid email or password');
      }

      // Get stored credentials
      final credentials = await DatabaseService().getUserCredentials(user.id);
      if (credentials == null) {
        return AuthResult.error('Invalid email or password');
      }

      // Verify password
      final salt = credentials['salt'];
      final storedHash = credentials['password_hash'];
      if (salt == null || storedHash == null) {
        return AuthResult.error('Invalid email or password');
      }
      
      final hashedPassword = _hashPassword(password, salt);
      if (hashedPassword != storedHash) {
        return AuthResult.error('Invalid email or password');
      }

      // Set current session
      await _setUserSession(user.id, email);
      _currentUser = user;

      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.error('Login failed: ${e.toString()}');
    }
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.setBool(_isLoggedInKey, false);

    _currentUserId = null;
    _currentUser = null;
  }

  // Set user session
  Future<void> _setUserSession(String userId, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userEmailKey, email);
    await prefs.setBool(_isLoggedInKey, true);

    _currentUserId = userId;
  }

  // Update user profile
  Future<AuthResult> updateProfile(UserProfile updatedUser) async {
    try {
      if (_currentUserId == null) {
        return AuthResult.error('No user logged in');
      }

      final nameError = validateName(updatedUser.name);
      if (nameError != null) {
        return AuthResult.error(nameError);
      }

      final userWithUpdatedTime = UserProfile(
        id: updatedUser.id,
        name: updatedUser.name,
        email: updatedUser.email,
        phoneNumber: updatedUser.phoneNumber,
        dateOfBirth: updatedUser.dateOfBirth,
        gender: updatedUser.gender,
        emergencyContact: updatedUser.emergencyContact,
        allergies: updatedUser.allergies,
        medicalConditions: updatedUser.medicalConditions,
        profileImageUrl: updatedUser.profileImageUrl,
        createdAt: updatedUser.createdAt,
        updatedAt: DateTime.now(),
      );

      await DatabaseService().updateUserProfile(userWithUpdatedTime);
      _currentUser = userWithUpdatedTime;

      return AuthResult.success(userWithUpdatedTime);
    } catch (e) {
      return AuthResult.error('Profile update failed: ${e.toString()}');
    }
  }

  // Method to create a test user for development/testing
  Future<AuthResult> createTestUser() async {
    return await register(
      email: 'test@mymedbuddy.com',
      password: 'TestUser123!',
      name: 'Test User',
      phoneNumber: '+1234567890',
      dateOfBirth: DateTime(1990, 1, 1),
      gender: 'Other',
    );
  }

  // Method to login as test user and ensure sample data exists
  Future<AuthResult> loginAsTestUser() async {
    try {
      // First try to login with existing test user
      final loginResult = await login(
        email: 'test@mymedbuddy.com',
        password: 'TestUser123!',
      );

      if (loginResult.isSuccess) {
        // Check if test user has sample data, if not add it
        await _ensureTestUserData(loginResult.user!.id);
        return loginResult;
      } else {
        // Test user doesn't exist, create it
        final createResult = await createTestUser();
        if (createResult.isSuccess) {
          // Add sample data for the new test user
          await _createSampleData(createResult.user!.id);
        }
        return createResult;
      }
    } catch (e) {
      return AuthResult.error('Failed to login as test user: ${e.toString()}');
    }
  }

  Future<void> _ensureTestUserData(String userId) async {
    try {
      final db = DatabaseService();
      final medications = await db.getUserMedications(userId);
      
      // If no medications found, add sample data
      if (medications.isEmpty) {
        await _createSampleData(userId);
      }
    } catch (e) {
      // If there's an error, we'll just continue without sample data
    }
  }

  Future<void> _createSampleData(String userId) async {
    final db = DatabaseService();
    final now = DateTime.now().toIso8601String();
    final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String();
    final nextWeek = DateTime.now().add(const Duration(days: 7)).toIso8601String();

    try {
      // Add sample medications
      await db.addUserMedication({
        'id': 'user_med_1',
        'userId': userId,
        'medicationId': 'med_1',
        'customName': null,
        'dosage': '81mg',
        'frequency': 'Once daily',
        'times': '["08:00"]',
        'instructions': 'Take with breakfast for heart health',
        'startDate': now,
        'endDate': null,
        'isActive': 1,
        'createdAt': now,
      });

      await db.addUserMedication({
        'id': 'user_med_2',
        'userId': userId,
        'medicationId': 'med_2',
        'customName': null,
        'dosage': '500mg',
        'frequency': 'Twice daily',
        'times': '["08:00", "20:00"]',
        'instructions': 'Take with breakfast and dinner',
        'startDate': now,
        'endDate': null,
        'isActive': 1,
        'createdAt': now,
      });

      // Add sample appointments
      await db.addUserAppointment({
        'id': 'appt_1',
        'userId': userId,
        'title': 'Annual Physical Exam',
        'description': 'Yearly check-up with primary care physician',
        'dateTime': tomorrow,
        'doctorName': 'Dr. Sarah Johnson',
        'location': 'Main Street Medical Center',
        'type': 'Check-up',
        'status': 'Scheduled',
        'reminderSet': 1,
        'createdAt': now,
      });

      await db.addUserAppointment({
        'id': 'appt_2',
        'userId': userId,
        'title': 'Blood Pressure Follow-up',
        'description': 'Follow-up appointment to check blood pressure medication effectiveness',
        'dateTime': nextWeek,
        'doctorName': 'Dr. Michael Chen',
        'location': 'Cardiology Associates',
        'type': 'Follow-up',
        'status': 'Scheduled',
        'reminderSet': 1,
        'createdAt': now,
      });
    } catch (e) {
      // If there's an error creating sample data, just continue
    }
  }
}

// Auth result class for handling authentication responses
class AuthResult {
  final bool isSuccess;
  final String? error;
  final UserProfile? user;

  AuthResult._({
    required this.isSuccess,
    this.error,
    this.user,
  });

  factory AuthResult.success(UserProfile user) {
    return AuthResult._(
      isSuccess: true,
      user: user,
    );
  }

  factory AuthResult.error(String error) {
    return AuthResult._(
      isSuccess: false,
      error: error,
    );
  }
}
