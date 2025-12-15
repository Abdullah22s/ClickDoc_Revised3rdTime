import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/doctor/doctor_registration_model.dart';

class DoctorRegistrationViewModel extends ChangeNotifier {
  bool isSaving = false;

  Future<String?> saveDoctorData({
    required DoctorRegistrationModel doctor,
  }) async {
    isSaving = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Check if email exists in patients collection
      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .get();

      if (patientDoc.exists) {
        isSaving = false;
        notifyListeners();
        return "This email is already registered as a patient. Cannot register as doctor.";
      }

      // Save doctor data
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .set(doctor.toMap());

      isSaving = false;
      notifyListeners();
      return null; // success
    } catch (e) {
      isSaving = false;
      notifyListeners();
      return "Error saving doctor data: $e";
    }
  }
}
