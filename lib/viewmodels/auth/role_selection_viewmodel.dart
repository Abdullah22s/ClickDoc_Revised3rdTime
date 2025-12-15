import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../views/doctor/doctor_registration_form_view.dart';
import '../../views/doctor/doctor_dashboard_view.dart';
import '../../views/patient/patient_form_view.dart';
import '../doctor/doctor_dashboard_viewmodel.dart';

class RoleSelectionViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sign out the current user
  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error signing out: $e')));
    }
  }

  /// Handle doctor selection from the role selection screen
  Future<void> handleDoctorSelection(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final email = user.email ?? '';

    try {
      // 1️⃣ Check if email is registered as patient
      final patientQuery = await _firestore
          .collection('patients')
          .where('email', isEqualTo: email)
          .get();

      if (patientQuery.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'This email is already registered as a patient. Cannot register as doctor.'),
          ),
        );
        return;
      }

      // 2️⃣ Check if doctor already exists
      final doctorQuery = await _firestore
          .collection('doctors')
          .where('email', isEqualTo: email)
          .get();

      if (doctorQuery.docs.isNotEmpty) {
        // ✅ Already registered doctor → go directly to dashboard
        final doctorViewModel = DoctorDashboardViewModel(
          userName: user.displayName ?? 'Doctor',
          userEmail: email,
          userPhotoUrl: user.photoURL,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorDashboardScreen(viewModel: doctorViewModel),
          ),
        );
        return;
      }

      // 3️⃣ New doctor → go to registration screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorRegistrationFormScreen(
            userName: user.displayName ?? 'Doctor',
            userEmail: email,
            userPhotoUrl: user.photoURL,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }


  void handlePatientSelection(BuildContext context, String? userName) {
    final user = _auth.currentUser;
    if (user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientFormScreen(userName: userName ?? 'User'),
      ),
    );
  }
}
