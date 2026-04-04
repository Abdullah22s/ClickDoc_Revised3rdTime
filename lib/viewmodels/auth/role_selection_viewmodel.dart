import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../views/doctor/doctor_registration_form_view.dart';
import '../../views/doctor/doctor_dashboard_view.dart';
import '../../views/patient/patient_form_view.dart';
import '../../views/ambulance/ambulance_registration_form_view.dart';
import '../../views/ambulance/ambulance_dashboard_view.dart'; // ✅ NEW IMPORT
import '../doctor/doctor_dashboard_viewmodel.dart';

class RoleSelectionViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sign out
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

  /// Doctor
  Future<void> handleDoctorSelection(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final email = user.email ?? '';

    try {
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

      final doctorQuery = await _firestore
          .collection('doctors')
          .where('email', isEqualTo: email)
          .get();

      if (doctorQuery.docs.isNotEmpty) {
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

  /// Patient
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

  /// 🚑 Ambulance (UPDATED)
  Future<void> handleAmbulanceSelection(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final email = user.email ?? '';

    try {
      // check patient
      final patientQuery = await _firestore
          .collection('patients')
          .where('email', isEqualTo: email)
          .get();

      if (patientQuery.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'This email is already registered as a patient. Cannot register as ambulance.'),
          ),
        );
        return;
      }

      // check doctor
      final doctorQuery = await _firestore
          .collection('doctors')
          .where('email', isEqualTo: email)
          .get();

      if (doctorQuery.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'This email is already registered as a doctor. Cannot register as ambulance.'),
          ),
        );
        return;
      }

      // ✅ check ambulance
      final ambulanceQuery = await _firestore
          .collection('ambulances')
          .where('email', isEqualTo: email)
          .get();

      if (ambulanceQuery.docs.isNotEmpty) {
        /// ✅ REDIRECT TO DASHBOARD INSTEAD OF SHOWING MESSAGE
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AmbulanceDashboardScreen(
              ambulanceEmail: email,
            ),
          ),
        );
        return;
      }

      // go to registration
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AmbulanceRegistrationFormScreen(
            userName: user.displayName ?? 'Ambulance',
            userEmail: email,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}