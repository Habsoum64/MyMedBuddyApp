import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/medication.dart';
import '../models/appointment.dart';
import '../models/health_tip.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseFirestore? _firestore;
  bool _isFirebaseAvailable = false;

  bool get isFirebaseAvailable => _isFirebaseAvailable;

  Future<void> initialize() async {
    await _initializeFirestore();
    if (_isFirebaseAvailable) {
      await initializeMockData();
    }
  }

  Future<void> _initializeFirestore() async {
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isNotEmpty) {
        _firestore = FirebaseFirestore.instance;
        _isFirebaseAvailable = true;
      } else {
        _isFirebaseAvailable = false;
      }
    } catch (e) {
      _isFirebaseAvailable = false;
    }
  }

  // Initialize mock data
  Future<void> initializeMockData() async {
    if (!_isFirebaseAvailable) {
      return;
    }
    
    try {
      // Check if data already exists
      final medicationsSnapshot = await _firestore!.collection('medications').limit(1).get();
      if (medicationsSnapshot.docs.isNotEmpty) {
        return; // Data already exists
      }

      // Add mock medications
      await _addMockMedications();
      await _addMockHealthTips();
    } catch (e) {
      // Error during initialization
    }
  }

  Future<void> _addMockMedications() async {
    if (!_isFirebaseAvailable) return;
    
    final medications = [
      {
        'id': 'med_1',
        'name': 'Aspirin',
        'genericName': 'Aspirin',
        'category': 'Pain Relief',
        'description': 'Pain reliever and fever reducer',
        'dosageForm': 'Tablet',
        'strength': '81mg',
        'manufacturer': 'Generic',
        'prescriptionRequired': false,
        'sideEffects': ['Stomach upset', 'Heartburn', 'Drowsiness'],
        'interactions': ['Warfarin', 'Ibuprofen'],
        'contraindications': ['Bleeding disorders', 'Stomach ulcers'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'med_2',
        'name': 'Metformin',
        'genericName': 'Metformin HCl',
        'category': 'Diabetes',
        'description': 'Medication for type 2 diabetes',
        'dosageForm': 'Tablet',
        'strength': '500mg',
        'manufacturer': 'Generic',
        'prescriptionRequired': true,
        'sideEffects': ['Nausea', 'Diarrhea', 'Metallic taste'],
        'interactions': ['Alcohol', 'Contrast dyes'],
        'contraindications': ['Kidney disease', 'Liver disease'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'med_3',
        'name': 'Lisinopril',
        'genericName': 'Lisinopril',
        'category': 'Blood Pressure',
        'description': 'ACE inhibitor for high blood pressure',
        'dosageForm': 'Tablet',
        'strength': '10mg',
        'manufacturer': 'Generic',
        'prescriptionRequired': true,
        'sideEffects': ['Dry cough', 'Dizziness', 'Fatigue'],
        'interactions': ['Potassium supplements', 'NSAIDs'],
        'contraindications': ['Pregnancy', 'Angioedema history'],
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final med in medications) {
      await _firestore!.collection('medications').doc(med['id'] as String).set(med);
    }
  }

  Future<void> _addMockHealthTips() async {
    if (!_isFirebaseAvailable) return;
    
    final healthTips = [
      {
        'id': 'tip_1',
        'title': 'Stay Hydrated',
        'category': 'General',
        'content': 'Drinking adequate water is crucial for maintaining good health. Aim for 8-10 glasses of water daily. Proper hydration helps with digestion, circulation, temperature regulation, and nutrient transportation. Signs of dehydration include dry mouth, fatigue, and dark urine.',
        'readingTime': 3,
        'tags': ['hydration', 'health', 'wellness'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'tip_2',
        'title': 'Exercise Regularly',
        'category': 'Fitness',
        'content': 'Regular physical activity is essential for maintaining good health. Aim for at least 150 minutes of moderate aerobic activity or 75 minutes of vigorous activity per week. Exercise helps improve cardiovascular health, strengthen muscles and bones, boost mood, and increase energy levels.',
        'readingTime': 4,
        'tags': ['exercise', 'fitness', 'health'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'tip_3',
        'title': 'Eat a Balanced Diet',
        'category': 'Nutrition',
        'content': 'A balanced diet provides the nutrients your body needs to function properly. Include a variety of fruits, vegetables, whole grains, lean proteins, and healthy fats in your meals. Limit processed foods, sugary drinks, and excessive amounts of salt and saturated fats.',
        'readingTime': 5,
        'tags': ['nutrition', 'diet', 'healthy eating'],
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final tip in healthTips) {
      await _firestore!.collection('health_tips').doc(tip['id'] as String).set(tip);
    }
  }

  // Get medications for a user
  Future<List<Medication>> getMedications(String userId) async {
    if (!_isFirebaseAvailable) return [];
    
    try {
      final snapshot = await _firestore!
          .collection('user_medications')
          .where('userId', isEqualTo: userId)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Medication.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Add medication for a user
  Future<void> addMedication(Medication medication) async {
    if (!_isFirebaseAvailable) return;
    
    try {
      await _firestore!
          .collection('user_medications')
          .doc(medication.id)
          .set(medication.toMap());
    } catch (e) {
      // Error adding medication
    }
  }

  // Update medication for a user
  Future<void> updateMedication(Medication medication) async {
    if (!_isFirebaseAvailable) return;
    
    try {
      await _firestore!
          .collection('user_medications')
          .doc(medication.id)
          .update(medication.toMap());
    } catch (e) {
      // Error updating medication
    }
  }

  // Delete medication for a user
  Future<void> deleteMedication(String medicationId) async {
    if (!_isFirebaseAvailable) return;
    
    try {
      await _firestore!
          .collection('user_medications')
          .doc(medicationId)
          .delete();
    } catch (e) {
      // Error deleting medication
    }
  }

  // Get appointments for a user
  Future<List<Appointment>> getAppointments(String userId) async {
    if (!_isFirebaseAvailable) return [];
    
    try {
      final snapshot = await _firestore!
          .collection('user_appointments')
          .where('userId', isEqualTo: userId)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Appointment.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Add appointment for a user
  Future<void> addAppointment(Appointment appointment) async {
    if (!_isFirebaseAvailable) return;
    
    try {
      await _firestore!
          .collection('user_appointments')
          .doc(appointment.id)
          .set(appointment.toMap());
    } catch (e) {
      // Error adding appointment
    }
  }

  // Update appointment for a user
  Future<void> updateAppointment(Appointment appointment) async {
    if (!_isFirebaseAvailable) return;
    
    try {
      await _firestore!
          .collection('user_appointments')
          .doc(appointment.id)
          .update(appointment.toMap());
    } catch (e) {
      // Error updating appointment
    }
  }

  // Delete appointment for a user
  Future<void> deleteAppointment(String appointmentId) async {
    if (!_isFirebaseAvailable) return;
    
    try {
      await _firestore!
          .collection('user_appointments')
          .doc(appointmentId)
          .delete();
    } catch (e) {
      // Error deleting appointment
    }
  }

  // Get health tips with optional filters
  Future<List<HealthTip>> getHealthTips({String? category, String? searchQuery}) async {
    if (!_isFirebaseAvailable) return _getMockHealthTips();
    
    try {
      Query query = _firestore!.collection('health_tips');
      
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }
      
      final snapshot = await query.get();
      
      List<HealthTip> tips = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return HealthTip.fromMap({...data, 'id': doc.id});
      }).toList();
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        tips = tips.where((tip) =>
            tip.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            tip.content.toLowerCase().contains(searchQuery.toLowerCase())).toList();
      }
      
      return tips;
    } catch (e) {
      return _getMockHealthTips();
    }
  }

  // Mock health tips for when Firebase is not available
  List<HealthTip> _getMockHealthTips() {
    return [
      HealthTip(
        id: 'tip_1',
        title: 'Stay Hydrated',
        category: 'General',
        content: 'Drinking adequate water is crucial for maintaining good health. Aim for 8-10 glasses of water daily. Proper hydration helps with digestion, circulation, temperature regulation, and nutrient transportation. Signs of dehydration include dry mouth, fatigue, and dark urine.',
        readingTime: 3,
        tags: ['hydration', 'health', 'wellness'],
        createdAt: DateTime.now(),
      ),
      HealthTip(
        id: 'tip_2',
        title: 'Exercise Regularly',
        category: 'Fitness',
        content: 'Regular physical activity is essential for maintaining good health. Aim for at least 150 minutes of moderate aerobic activity or 75 minutes of vigorous activity per week. Exercise helps improve cardiovascular health, strengthen muscles and bones, boost mood, and increase energy levels.',
        readingTime: 4,
        tags: ['exercise', 'fitness', 'health'],
        createdAt: DateTime.now(),
      ),
      HealthTip(
        id: 'tip_3',
        title: 'Eat a Balanced Diet',
        category: 'Nutrition',
        content: 'A balanced diet provides the nutrients your body needs to function properly. Include a variety of fruits, vegetables, whole grains, lean proteins, and healthy fats in your meals. Limit processed foods, sugary drinks, and excessive amounts of salt and saturated fats.',
        readingTime: 5,
        tags: ['nutrition', 'diet', 'healthy eating'],
        createdAt: DateTime.now(),
      ),
    ];
  }
}
