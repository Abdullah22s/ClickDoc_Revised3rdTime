import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchDoctorBySymptomViewModel extends ChangeNotifier {
  Map<String, dynamic> symptomMap = {};
  List<String> symptoms = [];
  List<String?> selectedSymptoms = [null]; // Start with 1 dropdown
  bool isLoading = false;
  List<Map<String, dynamic>> matchedDoctors = [];

  /// Load symptom JSON
  Future<void> loadSymptomData() async {
    final String jsonString =
    await rootBundle.loadString('assets/symptom_department_map.json');
    symptomMap = json.decode(jsonString);
    symptoms = symptomMap.keys.toList();
    notifyListeners();
  }

  /// Add symptom dropdown
  void addSymptomField() {
    if (selectedSymptoms.length < 3) {
      selectedSymptoms.add(null);
      notifyListeners();
    }
  }

  /// Remove symptom dropdown
  void removeSymptomField(int index) {
    if (selectedSymptoms.length > 1) {
      selectedSymptoms.removeAt(index);
      notifyListeners();
    }
  }

  /// Update selected symptom
  void updateSelectedSymptom(int index, String? value) {
    selectedSymptoms[index] = value;
    notifyListeners();
  }

  /// Search doctors based on selected symptoms
  Future<void> searchDoctors() async {
    final selected = selectedSymptoms
        .where((s) => s != null && s!.isNotEmpty)
        .cast<String>()
        .toList();

    if (selected.isEmpty) {
      matchedDoctors = [];
      notifyListeners();
      return;
    }

    isLoading = true;
    matchedDoctors = [];
    notifyListeners();

    // Predict departments based on symptoms
    final Set<String> predictedDepartments = {};
    for (var s in selected) {
      if (symptomMap.containsKey(s)) {
        predictedDepartments.addAll(List<String>.from(symptomMap[s]));
      }
    }

    // Collect all doctors including subcollections
    List<Map<String, dynamic>> allDoctors = [];
    final doctorsSnapshot =
    await FirebaseFirestore.instance.collection('doctors').get();

    for (var doc in doctorsSnapshot.docs) {
      final doctorId = doc.id;
      final doctorData = doc.data();

      final doctorName = doctorData['doctorName'] ??
          doctorData['name'] ??
          doctorData['doctor_name'] ??
          'Unknown Doctor';
      final doctorDepartment = doctorData['department'] ?? 'Unknown Department';

      // Physical OPDs
      final physicalOpds = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .collection('physical_opds')
          .get();

      for (var opd in physicalOpds.docs) {
        allDoctors.add({
          ...opd.data(),
          'id': opd.id,
          'type': 'Physical OPD',
          'doctorName': doctorName,
          'department': opd.data()['department'] ?? doctorDepartment,
        });
      }

      // Online Clinics
      final onlineClinics = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .collection('online_clinics')
          .get();

      for (var clinic in onlineClinics.docs) {
        allDoctors.add({
          ...clinic.data(),
          'id': clinic.id,
          'type': 'Online Clinic',
          'doctorName': doctorName,
          'department': clinic.data()['department'] ?? doctorDepartment,
        });
      }
    }

    // Filter doctors by predicted departments
    matchedDoctors = allDoctors.where((doc) {
      final dep = doc['department']?.toString().trim().toLowerCase();
      return dep != null &&
          predictedDepartments.any((p) => p.toLowerCase() == dep);
    }).toList();

    isLoading = false;
    notifyListeners();
  }
}
