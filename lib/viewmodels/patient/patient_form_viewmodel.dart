import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/patient/patient_form_model.dart';

class PatientFormViewModel extends ChangeNotifier {
  /// Controllers
  TextEditingController ageController = TextEditingController();
  TextEditingController weightController = TextEditingController();

  String? selectedGender;
  String? selectedBloodGroup;

  final List<String> bloodGroups = [
    'A+','A-','B+','B-','AB+','AB-','O+','O-'
  ];

  /// All possible illnesses
  final List<String> allDiseases = [
    'Diabetes',
    'Blood Pressure',
    'Heart Disease',
    'Asthma',
    'Arthritis',
    'Migraine',
    'Thyroid Disorder',
  ];

  /// Selected illnesses (max 3)
  List<String> selectedDiseases = [];

  /// Controls showing illness buttons
  bool showDiseaseOptions = false;

  bool isSaving = false;

  /// Remaining diseases (no duplicates)
  List<String> get availableDiseases {
    return allDiseases
        .where((d) => !selectedDiseases.contains(d))
        .toList();
  }

  /// Toggle illness option panel
  void toggleDiseaseOptions() {
    if (selectedDiseases.length < 3) {
      showDiseaseOptions = !showDiseaseOptions;
      notifyListeners();
    }
  }

  /// Select disease
  void selectDisease(String disease) {
    if (!selectedDiseases.contains(disease) &&
        selectedDiseases.length < 3) {
      selectedDiseases.add(disease);
      showDiseaseOptions = false;
      notifyListeners();
    }
  }

  /// Remove disease
  void removeDisease(String disease) {
    selectedDiseases.remove(disease);
    notifyListeners();
  }

  /// Random 5-character reference
  String generateReferenceNumber() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(5, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Save data
  Future<void> savePatientData({
    required String userName,
    required BuildContext context,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    isSaving = true;
    notifyListeners();

    try {
      final patient = PatientFormModel(
        referenceNumber: generateReferenceNumber(),
        name: userName,
        email: user.email ?? "",
        age: ageController.text.trim(),
        weight: weightController.text.trim(),
        gender: selectedGender ?? "",
        bloodGroup: selectedBloodGroup ?? "",
        medicalHistory: selectedDiseases,
      );

      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .set(patient.toMap());

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
