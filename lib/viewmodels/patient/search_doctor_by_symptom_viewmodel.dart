import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchDoctorBySymptomViewModel extends ChangeNotifier {
  Map<String, dynamic> symptomMap = {};

  List<String> allSymptoms = [];
  List<String> symptoms = [];
  List<String?> selectedSymptoms = [null];

  bool isLoading = false;
  List<Map<String, dynamic>> matchedDoctors = [];

  static const int maxSteps = 3;

  /// Load JSON
  Future<void> loadSymptomData() async {
    final jsonString =
    await rootBundle.loadString('assets/symptom_department_map.json');

    symptomMap = json.decode(jsonString);
    allSymptoms = symptomMap.keys.toList();

    symptoms = List.from(allSymptoms);
    selectedSymptoms = [null];

    notifyListeners();
  }

  void addSymptomField() {
    if (selectedSymptoms.length < maxSteps) {
      selectedSymptoms.add(null);
      notifyListeners();
    }
  }

  void removeSymptomField(int index) {
    if (selectedSymptoms.length > 1) {
      selectedSymptoms.removeAt(index);
      symptoms = List.from(allSymptoms);
      notifyListeners();
    }
  }

  void updateSelectedSymptom(int index, String? value) {
    if (value == null) return;

    selectedSymptoms[index] = value;

    final selected = selectedSymptoms
        .where((s) => s != null)
        .cast<String>()
        .toList();

    final Set<String> relatedDepartments = {};
    for (var s in selected) {
      relatedDepartments.addAll(List<String>.from(symptomMap[s]));
    }

    final narrowed = symptomMap.entries
        .where((entry) {
      final deps = List<String>.from(entry.value);
      return deps.any((d) => relatedDepartments.contains(d));
    })
        .map((e) => e.key)
        .toSet()
        .toList();

    symptoms = {
      ...narrowed,
      ...selected,
    }.toList();

    if (index == selectedSymptoms.length - 1 &&
        selectedSymptoms.length < maxSteps) {
      selectedSymptoms.add(null);
    }

    notifyListeners();
  }

  /// Search doctors
  Future<void> searchDoctors() async {
    final selected = selectedSymptoms
        .where((s) => s != null && s!.isNotEmpty)
        .cast<String>()
        .toList();

    if (selected.isEmpty) return;

    isLoading = true;
    matchedDoctors = [];
    notifyListeners();

    final Set<String> predictedDepartments = {};
    for (var s in selected) {
      predictedDepartments.addAll(List<String>.from(symptomMap[s]));
    }

    final doctorsSnapshot =
    await FirebaseFirestore.instance.collection('doctors').get();

    List<Map<String, dynamic>> allDoctors = [];

    for (var doc in doctorsSnapshot.docs) {
      final doctorId = doc.id;
      final doctorData = doc.data();

      final doctorName =
          doctorData['doctorName'] ?? doctorData['name'] ?? 'Unknown Doctor';

      // Pick a primary department for card display
      String mainDepartment = doctorData['department'] ??
          (predictedDepartments.isNotEmpty
              ? predictedDepartments.first
              : 'Unknown Department');

      final doctorEntry = {
        'doctorId': doctorId,
        'doctorName': doctorName,
        'mainDepartment': mainDepartment,
        'opds': <Map<String, dynamic>>[],
        'onlineClinics': <Map<String, dynamic>>[],
      };

      // Physical OPDs
      final physicalOpds = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .collection('physical_opds')
          .get();

      for (var opd in physicalOpds.docs) {
        final data = opd.data();
        if (predictedDepartments
            .contains(data['department'] ?? doctorData['department'])) {
          doctorEntry['opds'].add({
            ...data,
            'type': 'Physical OPD',
          });
        }
      }

      // Online Clinics
      final onlineClinics = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .collection('online_clinics')
          .get();

      for (var clinic in onlineClinics.docs) {
        final data = clinic.data();
        if (predictedDepartments
            .contains(data['department'] ?? doctorData['department'])) {
          doctorEntry['onlineClinics'].add({
            ...data,
            'type': 'Online Clinic',
          });
        }
      }

      if ((doctorEntry['opds'] as List).isNotEmpty ||
          (doctorEntry['onlineClinics'] as List).isNotEmpty) {
        allDoctors.add(doctorEntry);
      }
    }

    matchedDoctors = allDoctors;
    isLoading = false;
    notifyListeners();
  }
}
