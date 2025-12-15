import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/patient/patient_profile_model.dart';

class PatientProfileViewModel extends ChangeNotifier {
  final String userEmail;
  PatientProfileModel? patient;
  bool loading = true;

  PatientProfileViewModel({required this.userEmail}) {
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('patients')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        patient = PatientProfileModel.fromMap(query.docs.first.data());
      }
    } catch (e) {
      debugPrint("Error fetching patient info: $e");
    }
    loading = false;
    notifyListeners();
  }
}
