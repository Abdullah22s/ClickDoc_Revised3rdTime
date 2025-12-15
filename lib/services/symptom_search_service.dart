import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SymptomSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Load the symptom-to-department mapping from JSON asset
  Future<Map<String, List<String>>> _loadSymptomMap() async {
    final String data =
    await rootBundle.loadString('assets/symptom_department_map.json');
    final Map<String, dynamic> jsonMap = json.decode(data);

    // Convert dynamic lists to List<String>
    return jsonMap.map((key, value) =>
        MapEntry(key.toLowerCase(), List<String>.from(value)));
  }

  /// Predict most likely departments based on up to 3 user symptoms
  Future<List<String>> getDepartmentsForSymptoms(List<String> symptoms) async {
    final symptomMap = await _loadSymptomMap();
    final Map<String, int> departmentFrequency = {};

    for (final symptom in symptoms) {
      final lowerSymptom = symptom.toLowerCase().trim();
      if (symptomMap.containsKey(lowerSymptom)) {
        for (final dept in symptomMap[lowerSymptom]!) {
          departmentFrequency[dept] = (departmentFrequency[dept] ?? 0) + 1;
        }
      }
    }

    // Sort by frequency (more matches = more relevant)
    final sortedDepartments = departmentFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedDepartments.map((e) => e.key).toList();
  }

  /// Fetch doctors that match predicted departments
  /// from both online clinics and physical OPDs
  Future<List<Map<String, dynamic>>> getDoctorsForDepartments(
      List<String> departments) async {
    List<Map<String, dynamic>> matchedDoctors = [];

    // Fetch all doctors
    final doctorsSnapshot = await _firestore.collection('doctors').get();

    for (final doc in doctorsSnapshot.docs) {
      final doctorUid = doc.id;
      final doctorData = doc.data();

      // Fetch doctor’s online clinics
      final onlineClinics = await _firestore
          .collection('doctors')
          .doc(doctorUid)
          .collection('online_clinics')
          .get();

      for (final clinic in onlineClinics.docs) {
        final data = clinic.data();
        if (departments.contains(data['department'])) {
          matchedDoctors.add({
            'doctorId': doctorUid,
            'doctorName': doctorData['name'] ?? 'Unknown',
            'department': data['department'],
            'type': 'Online Clinic',
          });
        }
      }

      // Fetch doctor’s physical OPDs
      final physicalOpds = await _firestore
          .collection('doctors')
          .doc(doctorUid)
          .collection('physical_opds')
          .get();

      for (final opd in physicalOpds.docs) {
        final data = opd.data();
        if (departments.contains(data['department'])) {
          matchedDoctors.add({
            'doctorId': doctorUid,
            'doctorName': doctorData['name'] ?? 'Unknown',
            'department': data['department'],
            'type': 'Physical OPD',
            'hospitalName': data['hospitalName'] ?? '',
          });
        }
      }
    }

    return matchedDoctors;
  }

  /// Combined function – takes symptoms and returns matching doctors
  Future<List<Map<String, dynamic>>> searchDoctorsBySymptoms(
      List<String> symptoms) async {
    final departments = await getDepartmentsForSymptoms(symptoms);
    if (departments.isEmpty) return [];
    return getDoctorsForDepartments(departments);
  }
}
