import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/patient/patient_form_model.dart';

class PatientFormViewModel extends ChangeNotifier {
  TextEditingController ageController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  String? selectedGender;

  List<String> diseases = [
    'None',
    'Diabetes',
    'Blood Pressure',
    'Heart Disease',
    'Asthma',
    'Arthritis',
    'Migraine',
    'Thyroid Disorder',
  ];

  List<String?> selectedDiseases = [null];

  bool isSaving = false;

  void addDiseaseRow(int index, String? value) {
    selectedDiseases[index] = value;

    if (value != null && value != "None" && index == selectedDiseases.length - 1) {
      selectedDiseases.add(null);
    }
    notifyListeners();
  }

  void removeDiseaseRow(int index) {
    selectedDiseases.removeAt(index);
    if (selectedDiseases.isEmpty) {
      selectedDiseases = [null];
    }
    notifyListeners();
  }

  Future<void> savePatientData({required String userName, required BuildContext context}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    isSaving = true;
    notifyListeners();

    try {
      List<String> finalDiseases = selectedDiseases
          .where((d) => d != null && d != "None")
          .map((d) => d!)
          .toList();

      PatientFormModel patient = PatientFormModel(
        name: userName,
        email: user.email ?? "",
        age: ageController.text.trim(),
        weight: weightController.text.trim(),
        gender: selectedGender ?? "",
        medicalHistory: finalDiseases,
      );

      await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .set(patient.toMap());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving data: $e")),
      );
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
