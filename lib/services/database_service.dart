import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_profile.dart';
import '../models/medication_log.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mymedbuddy.db');
    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create user profile table
    await db.execute('''
      CREATE TABLE user_profiles(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        dateOfBirth TEXT,
        gender TEXT,
        phoneNumber TEXT,
        emergencyContact TEXT,
        allergies TEXT,
        medicalConditions TEXT,
        profileImageUrl TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create user credentials table
    await db.execute('''
      CREATE TABLE user_credentials(
        userId TEXT PRIMARY KEY,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES user_profiles (id)
      )
    ''');

    // Create medications table (for all available medications)
    await db.execute('''
      CREATE TABLE medications_catalog(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL,
        category TEXT,
        sideEffects TEXT,
        instructions TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create user medications table (user-specific medications)
    await db.execute('''
      CREATE TABLE user_medications(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        medicationId TEXT,
        customName TEXT,
        dosage TEXT NOT NULL,
        frequency TEXT NOT NULL,
        times TEXT,
        instructions TEXT,
        startDate TEXT NOT NULL,
        endDate TEXT,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES user_profiles (id),
        FOREIGN KEY (medicationId) REFERENCES medications_catalog (id)
      )
    ''');

    // Create user appointments table
    await db.execute('''
      CREATE TABLE user_appointments(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        dateTime TEXT NOT NULL,
        doctorName TEXT,
        location TEXT,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        reminderSet INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES user_profiles (id)
      )
    ''');

    // Create health tips table
    await db.execute('''
      CREATE TABLE health_tips(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT NOT NULL,
        tags TEXT,
        author TEXT,
        sourceUrl TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create medication logs table
    await db.execute('''
      CREATE TABLE medication_logs(
        id TEXT PRIMARY KEY,
        medicationId TEXT NOT NULL,
        medicationName TEXT NOT NULL,
        scheduledTime TEXT NOT NULL,
        takenTime TEXT,
        status TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // Insert sample data
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    final now = DateTime.now().toIso8601String();
    
    // Insert comprehensive medications catalog
    final medications = [
      {
        'id': 'med_1',
        'name': 'Aspirin',
        'description': 'Pain reliever and anti-inflammatory medication',
        'type': 'Tablet',
        'category': 'Pain Relief',
        'sideEffects': 'Stomach upset, nausea',
        'instructions': 'Take with food',
        'createdAt': now,
      },
      {
        'id': 'med_2', 
        'name': 'Metformin',
        'description': 'Medication for type 2 diabetes',
        'type': 'Tablet',
        'category': 'Diabetes',
        'sideEffects': 'Nausea, diarrhea',
        'instructions': 'Take with meals',
        'createdAt': now,
      },
      {
        'id': 'med_3',
        'name': 'Lisinopril', 
        'description': 'ACE inhibitor for high blood pressure',
        'type': 'Tablet',
        'category': 'Blood Pressure',
        'sideEffects': 'Dizziness, dry cough',
        'instructions': 'Take at the same time daily',
        'createdAt': now,
      },
      {
        'id': 'med_4',
        'name': 'Ibuprofen',
        'description': 'Non-steroidal anti-inflammatory drug (NSAID)',
        'type': 'Tablet',
        'category': 'Pain Relief',
        'sideEffects': 'Stomach irritation, heartburn',
        'instructions': 'Take with food or milk',
        'createdAt': now,
      },
      {
        'id': 'med_5',
        'name': 'Simvastatin',
        'description': 'Statin medication for lowering cholesterol',
        'type': 'Tablet',
        'category': 'Cholesterol',
        'sideEffects': 'Muscle pain, liver problems',
        'instructions': 'Take in the evening',
        'createdAt': now,
      },
      {
        'id': 'med_6',
        'name': 'Omeprazole',
        'description': 'Proton pump inhibitor for acid reflux',
        'type': 'Capsule',
        'category': 'Digestive',
        'sideEffects': 'Headache, nausea',
        'instructions': 'Take before meals',
        'createdAt': now,
      },
      {
        'id': 'med_7',
        'name': 'Levothyroxine',
        'description': 'Thyroid hormone replacement',
        'type': 'Tablet',
        'category': 'Thyroid',
        'sideEffects': 'Heart palpitations if overdosed',
        'instructions': 'Take on empty stomach',
        'createdAt': now,
      },
      {
        'id': 'med_8',
        'name': 'Losartan',
        'description': 'ARB medication for high blood pressure',
        'type': 'Tablet',
        'category': 'Blood Pressure',
        'sideEffects': 'Dizziness, fatigue',
        'instructions': 'Can be taken with or without food',
        'createdAt': now,
      },
      {
        'id': 'med_9',
        'name': 'Sertraline',
        'description': 'SSRI antidepressant',
        'type': 'Tablet',
        'category': 'Mental Health',
        'sideEffects': 'Nausea, drowsiness, dry mouth',
        'instructions': 'Take at the same time daily',
        'createdAt': now,
      },
      {
        'id': 'med_10',
        'name': 'Albuterol',
        'description': 'Bronchodilator for asthma and COPD',
        'type': 'Inhaler',
        'category': 'Respiratory',
        'sideEffects': 'Shakiness, rapid heartbeat',
        'instructions': 'Shake before use',
        'createdAt': now,
      }
    ];

    for (final medication in medications) {
      await db.insert('medications_catalog', medication);
    }

    // Insert comprehensive health tips library
    await db.insert('health_tips', {
      'id': 'tip_1',
      'title': 'Stay Hydrated',
      'content': 'Drink at least 8 glasses of water daily to maintain proper hydration and support overall health. Water helps regulate body temperature, transport nutrients, and flush out toxins.',
      'category': 'General Health',
      'tags': 'hydration,water,health',
      'author': 'MyMedBuddy Team',
      'sourceUrl': '',
      'createdAt': now,
    });

    await db.insert('health_tips', {
      'id': 'tip_2',
      'title': 'Exercise Regularly',
      'content': 'Aim for at least 30 minutes of moderate exercise 5 days a week to improve cardiovascular health. Regular physical activity strengthens your heart, improves circulation, and boosts mood.',
      'category': 'Exercise',
      'tags': 'exercise,fitness,heart,cardiovascular',
      'author': 'MyMedBuddy Team',
      'sourceUrl': '',
      'createdAt': now,
    });

    await db.insert('health_tips', {
      'id': 'tip_3',
      'title': 'Medication Adherence',
      'content': 'Take your medications as prescribed. Set reminders to help you remember your daily doses. Never skip doses or stop taking medications without consulting your healthcare provider.',
      'category': 'Medication',
      'tags': 'medication,adherence,reminder,prescription',
      'author': 'MyMedBuddy Team',
      'sourceUrl': '',
      'createdAt': now,
    });

    await db.insert('health_tips', {
      'id': 'tip_4',
      'title': 'Healthy Diet',
      'content': 'Focus on a balanced diet rich in fruits, vegetables, whole grains, and lean proteins. Limit processed foods, sugar, and excessive sodium intake.',
      'category': 'Nutrition',
      'tags': 'diet,nutrition,healthy eating,balanced',
      'author': 'MyMedBuddy Team',
      'sourceUrl': '',
      'createdAt': now,
    });

    await db.insert('health_tips', {
      'id': 'tip_5',
      'title': 'Quality Sleep',
      'content': 'Get 7-9 hours of quality sleep each night. Establish a consistent sleep schedule, create a comfortable sleep environment, and avoid screens before bedtime.',
      'category': 'Sleep',
      'tags': 'sleep,rest,sleep hygiene,bedtime',
      'author': 'MyMedBuddy Team',
      'sourceUrl': '',
      'createdAt': now,
    });

    await db.insert('health_tips', {
      'id': 'tip_6',
      'title': 'Stress Management',
      'content': 'Practice stress-reduction techniques such as deep breathing, meditation, or yoga. Chronic stress can negatively impact your physical and mental health.',
      'category': 'Mental Health',
      'tags': 'stress,mental health,meditation,relaxation',
      'author': 'MyMedBuddy Team',
      'sourceUrl': '',
      'createdAt': now,
    });

    await db.insert('health_tips', {
      'id': 'tip_7',
      'title': 'Regular Health Checkups',
      'content': 'Schedule routine health checkups and screenings as recommended by your healthcare provider. Early detection and prevention are key to maintaining good health.',
      'category': 'Preventive Care',
      'tags': 'checkups,prevention,screening,healthcare',
      'author': 'MyMedBuddy Team',
      'sourceUrl': '',
      'createdAt': now,
    });

    await db.insert('health_tips', {
      'id': 'tip_8',
      'title': 'Hand Hygiene',
      'content': 'Wash your hands frequently with soap and water for at least 20 seconds. Proper hand hygiene is one of the most effective ways to prevent illness.',
      'category': 'Hygiene',
      'tags': 'hand washing,hygiene,prevention,germs',
      'author': 'MyMedBuddy Team',
      'sourceUrl': '',
      'createdAt': now,
    });

    await db.insert('health_tips', {
      'id': 'tip_9',
      'title': 'Limit Alcohol and Avoid Smoking',
      'content': 'If you drink alcohol, do so in moderation. Avoid smoking and secondhand smoke exposure. Both can significantly impact your health and medication effectiveness.',
      'category': 'Lifestyle',
      'tags': 'alcohol,smoking,lifestyle,moderation',
      'author': 'MyMedBuddy Team',
      'sourceUrl': '',
      'createdAt': now,
    });

    await db.insert('health_tips', {
      'id': 'tip_10',
      'title': 'Stay Connected',
      'content': 'Maintain social connections and relationships. Social support is important for mental health and can help you manage stress and stay motivated in your health journey.',
      'category': 'Mental Health',
      'tags': 'social,relationships,mental health,support',
      'author': 'MyMedBuddy Team',
      'sourceUrl': '',
      'createdAt': now,
    });

    await db.insert('health_tips', {
      'id': 'tip_11',
      'title': 'Protect Your Skin',
      'content': 'Use sunscreen with at least SPF 30 when outdoors. Wear protective clothing and seek shade during peak sun hours (10 AM to 4 PM) to prevent skin damage.',
      'category': 'Preventive Care',
      'tags': 'sunscreen,skin protection,UV,prevention',
      'author': 'MyMedBuddy Team',
      'sourceUrl': '',
      'createdAt': now,
    });

    await db.insert('health_tips', {
      'id': 'tip_12',
      'title': 'Monitor Your Vital Signs',
      'content': 'Keep track of important health metrics like blood pressure, heart rate, and weight. Regular monitoring helps you and your healthcare provider detect changes early.',
      'category': 'Health Monitoring',
      'tags': 'vital signs,blood pressure,monitoring,tracking',
      'author': 'MyMedBuddy Team',
      'sourceUrl': '',
      'createdAt': now,
    });

    await db.insert('health_tips', {
      'id': 'tip_13',
      'title': 'Strength Training',
      'content': 'Include strength training exercises at least twice a week. Building muscle mass helps maintain bone density, improves metabolism, and supports overall functional fitness.',
      'category': 'Exercise',
      'tags': 'strength training,muscle,bones,metabolism',
      'author': 'MyMedBuddy Team',
      'sourceUrl': '',
      'createdAt': now,
    });

    await db.insert('health_tips', {
      'id': 'tip_14',
      'title': 'Mindful Eating',
      'content': 'Practice mindful eating by paying attention to hunger cues, eating slowly, and savoring your food. This helps with digestion and can prevent overeating.',
      'category': 'Nutrition',
      'tags': 'mindful eating,digestion,portion control,awareness',
      'author': 'MyMedBuddy Team',
      'sourceUrl': '',
      'createdAt': now,
    });

    await db.insert('health_tips', {
      'id': 'tip_15',
      'title': 'Emergency Preparedness',
      'content': 'Keep a list of emergency contacts, medications, and medical conditions easily accessible. Know the location of the nearest hospital and have a basic first aid kit at home.',
      'category': 'Emergency',
      'tags': 'emergency,preparedness,first aid,contacts',
      'author': 'MyMedBuddy Team',
      'sourceUrl': '',
      'createdAt': now,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // For any version upgrade, recreate all tables to ensure consistency
    await db.execute('DROP TABLE IF EXISTS medication_logs');
    await db.execute('DROP TABLE IF EXISTS health_tips');
    await db.execute('DROP TABLE IF EXISTS user_appointments');
    await db.execute('DROP TABLE IF EXISTS user_medications');
    await db.execute('DROP TABLE IF EXISTS medications_catalog');
    await db.execute('DROP TABLE IF EXISTS user_credentials');
    await db.execute('DROP TABLE IF EXISTS user_profiles');
    
    // Recreate all tables
    await _onCreate(db, newVersion);
  }

  // User Profile Operations
  Future<int> insertUserProfile(UserProfile profile) async {
    final db = await database;
    final map = profile.toMap();
    map['allergies'] = profile.allergies.join(',');
    map['medicalConditions'] = profile.medicalConditions.join(',');
    
    return await db.insert('user_profiles', map);
  }

  Future<UserProfile?> getUserProfile(String id) async {
    final db = await database;
    final maps = await db.query(
      'user_profiles',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final map = Map<String, dynamic>.from(maps.first);
      map['allergies'] = map['allergies']?.split(',') ?? [];
      map['medicalConditions'] = map['medicalConditions']?.split(',') ?? [];
      return UserProfile.fromMap(map);
    }
    return null;
  }

  Future<int> updateUserProfile(UserProfile profile) async {
    final db = await database;
    final map = profile.toMap();
    map['allergies'] = profile.allergies.join(',');
    map['medicalConditions'] = profile.medicalConditions.join(',');
    
    return await db.update(
      'user_profiles',
      map,
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  // Authentication Operations
  Future<UserProfile?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'user_profiles',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      final map = Map<String, dynamic>.from(maps.first);
      map['allergies'] = map['allergies']?.split(',') ?? [];
      map['medicalConditions'] = map['medicalConditions']?.split(',') ?? [];
      return UserProfile.fromMap(map);
    }
    return null;
  }

  Future<void> insertUserCredentials(String userId, String passwordHash, String salt) async {
    final db = await database;
    await db.insert('user_credentials', {
      'userId': userId,
      'password_hash': passwordHash,
      'salt': salt,
    });
  }

  Future<Map<String, String>?> getUserCredentials(String userId) async {
    final db = await database;
    final maps = await db.query(
      'user_credentials',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      return {
        'password_hash': map['password_hash'] as String,
        'salt': map['salt'] as String,
      };
    }
    return null;
  }

  // Medication Log Operations
  Future<int> insertMedicationLog(MedicationLog log) async {
    final db = await database;
    return await db.insert('medication_logs', log.toMap());
  }

  Future<List<MedicationLog>> getMedicationLogs({
    String? medicationId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (medicationId != null) {
      whereClause += ' AND medicationId = ?';
      whereArgs.add(medicationId);
    }
    
    if (startDate != null) {
      whereClause += ' AND scheduledTime >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      whereClause += ' AND scheduledTime <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final maps = await db.query(
      'medication_logs',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'scheduledTime DESC',
    );

    return List.generate(maps.length, (i) {
      return MedicationLog.fromMap(maps[i]);
    });
  }

  Future<int> updateMedicationLog(MedicationLog log) async {
    final db = await database;
    return await db.update(
      'medication_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteMedicationLog(String id) async {
    final db = await database;
    return await db.delete(
      'medication_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // User-specific data retrieval methods
  Future<List<Map<String, dynamic>>> getUserMedications(String userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT um.*, mc.name as catalogName, mc.description, mc.type, mc.category, mc.sideEffects
      FROM user_medications um
      LEFT JOIN medications_catalog mc ON um.medicationId = mc.id
      WHERE um.userId = ? AND um.isActive = 1
      ORDER BY um.createdAt DESC
    ''', [userId]);
  }

  Future<List<Map<String, dynamic>>> getUserAppointments(String userId) async {
    final db = await database;
    return await db.query(
      'user_appointments',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dateTime ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllHealthTips() async {
    final db = await database;
    return await db.query(
      'health_tips',
      orderBy: 'createdAt DESC',
    );
  }

  // Search health tips by title, content, or tags
  Future<List<Map<String, dynamic>>> searchHealthTips(String query) async {
    final db = await database;
    return await db.query(
      'health_tips',
      where: 'title LIKE ? OR content LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
  }

  // Get health tips by category
  Future<List<Map<String, dynamic>>> getHealthTipsByCategory(String category) async {
    final db = await database;
    return await db.query(
      'health_tips',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'createdAt DESC',
    );
  }

  // Get all medications from catalog (global)
  Future<List<Map<String, dynamic>>> getMedicationsCatalog() async {
    final db = await database;
    final results = await db.query(
      'medications_catalog',
      orderBy: 'name ASC',
    );
    return results;
  }

  // Search medications catalog by name or category
  Future<List<Map<String, dynamic>>> searchMedicationsCatalog(String query) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT * FROM medications_catalog 
      WHERE name LIKE ? OR category LIKE ? OR description LIKE ?
      ORDER BY name ASC
    ''', ['%$query%', '%$query%', '%$query%']);
    return results;
  }

  // Add user medication
  Future<int> addUserMedication(Map<String, dynamic> medication) async {
    final db = await database;
    return await db.insert('user_medications', medication);
  }

  // Add user appointment
  Future<int> addUserAppointment(Map<String, dynamic> appointment) async {
    final db = await database;
    return await db.insert('user_appointments', appointment);
  }

  // Update user medication
  Future<int> updateUserMedication(String id, Map<String, dynamic> medication) async {
    final db = await database;
    return await db.update(
      'user_medications',
      medication,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update user appointment
  Future<int> updateUserAppointment(String id, Map<String, dynamic> appointment) async {
    final db = await database;
    return await db.update(
      'user_appointments',
      appointment,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete user medication
  Future<int> deleteUserMedication(String id) async {
    final db = await database;
    return await db.update(
      'user_medications',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete user appointment
  Future<int> deleteUserAppointment(String id) async {
    final db = await database;
    return await db.delete(
      'user_appointments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Export functionality
  Future<List<Map<String, dynamic>>> exportMedicationLogs() async {
    final db = await database;
    return await db.query('medication_logs', orderBy: 'scheduledTime DESC');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
