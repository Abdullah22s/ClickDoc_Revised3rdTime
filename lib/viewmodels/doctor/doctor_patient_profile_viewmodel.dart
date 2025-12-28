import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/patient/patient_model.dart';

class DoctorPatientProfileViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PatientModel? patient;
  bool isLoading = true;

  /// Fetch patient by referenceNumber
  Future<void> fetchPatientByReferenceNumber(String referenceNumber) async {
    isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('patients')
          .where('referenceNumber', isEqualTo: referenceNumber.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        patient = PatientModel.fromMap(doc.id, doc.data());
      } else {
        patient = null;
        print("Patient not found for referenceNumber: $referenceNumber");
      }
    } catch (e) {
      print("Error fetching patient: $e");
      patient = null;
    }

    isLoading = false;
    notifyListeners();
  }
}
