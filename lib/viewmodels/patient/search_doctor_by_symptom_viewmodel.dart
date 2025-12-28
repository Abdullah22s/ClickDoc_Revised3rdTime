import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchDoctorBySymptomViewModel extends ChangeNotifier {
  Map<String, List<String>> symptomMap = {};

  /// Controllers for text fields
  List<TextEditingController> symptomControllers = [TextEditingController()];

  static const int maxSymptoms = 3;

  bool isLoading = false;
  List<Map<String, dynamic>> matchedDoctors = [];

  /// Messages for departments with no available doctor
  List<String> predictedDepartmentMessages = [];

  /// Load JSON
  Future<void> loadSymptomData() async {
    final jsonString =
    await rootBundle.loadString('assets/symptom_department_map.json');

    final Map<String, dynamic> raw = json.decode(jsonString);

    symptomMap = raw.map(
          (key, value) => MapEntry(key.toLowerCase(), List<String>.from(value)),
    );

    notifyListeners();
  }

  /// Add symptom input
  void addSymptomField() {
    if (symptomControllers.length < maxSymptoms) {
      symptomControllers.add(TextEditingController());
      notifyListeners();
    }
  }

  /// Remove symptom input
  void removeSymptomField(int index) {
    if (symptomControllers.length > 1) {
      symptomControllers.removeAt(index);
      notifyListeners();
    }
  }

  /// MAIN SEARCH (Random Forest–style voting with multiple departments)
  Future<void> searchDoctors() async {
    final symptoms = symptomControllers
        .map((c) => c.text.toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (symptoms.isEmpty) return;

    isLoading = true;
    matchedDoctors = [];
    predictedDepartmentMessages = [];
    notifyListeners();

    /// 1️⃣ Department voting
    final Map<String, int> departmentVotes = {};
    for (final symptom in symptoms) {
      if (symptomMap.containsKey(symptom)) {
        for (final dept in symptomMap[symptom]!) {
          departmentVotes[dept] = (departmentVotes[dept] ?? 0) + 1;
        }
      }
    }

    if (departmentVotes.isEmpty) {
      isLoading = false;
      notifyListeners();
      return;
    }

    /// 2️⃣ Departments with at least 2 votes
    final suggestedDepartments = departmentVotes.entries
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .toList();

    /// 3️⃣ If none reach 2 votes, pick the top one
    final departmentsToShow =
    suggestedDepartments.isNotEmpty ? suggestedDepartments : [departmentVotes.entries.first.key];

    /// 4️⃣ Fetch doctors matching suggested departments
    final doctorsSnapshot =
    await FirebaseFirestore.instance.collection('doctors').get();

    for (var doc in doctorsSnapshot.docs) {
      final doctorId = doc.id;
      final doctorData = doc.data();

      final doctorEntry = {
        'doctorId': doctorId,
        'doctorName': doctorData['name'] ?? 'Unknown Doctor',
        'departments': <String>{},
      };

      /// Physical OPDs
      final physicalOpds = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .collection('physical_opds')
          .get();

      for (var opd in physicalOpds.docs) {
        if (departmentsToShow.contains(opd['department'])) {
          doctorEntry['departments'].add(opd['department']);
        }
      }

      /// Online Clinics
      final onlineClinics = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .collection('online_clinics')
          .get();

      for (var clinic in onlineClinics.docs) {
        if (departmentsToShow.contains(clinic['department'])) {
          doctorEntry['departments'].add(clinic['department']);
        }
      }

      if ((doctorEntry['departments'] as Set).isNotEmpty) {
        matchedDoctors.add(doctorEntry);
      }
    }

    /// 5️⃣ Generate messages only for departments with NO available doctor
    predictedDepartmentMessages = departmentsToShow.map((dept) {
      final doctorExists = matchedDoctors.any(
              (d) => (d['departments'] as Set).contains(dept));
      return doctorExists ? null : "You may consult $dept.";
    }).whereType<String>().toList(); // remove nulls

    isLoading = false;
    notifyListeners();
  }
}
