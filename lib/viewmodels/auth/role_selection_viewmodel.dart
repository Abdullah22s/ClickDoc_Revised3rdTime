import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service and View Imports
import '../../services/ambulance_location_service.dart';
import '../../views/doctor/doctor_registration_form_view.dart';
import '../../views/doctor/doctor_dashboard_view.dart';
import '../../views/patient/patient_form_view.dart';
import '../../views/ambulance/ambulance_registration_form_view.dart';
import '../../views/ambulance/ambulance_dashboard_view.dart';
import '../../views/Operator/operator_registration_form_view.dart';
import '../../views/Operator/operator_dashboard_view.dart';
import '../doctor/doctor_dashboard_viewmodel.dart';

class RoleSelectionViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Logs the user out of Firebase and Google
  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      debugPrint("Sign out error: $e");
      _showError(context, "Error signing out: $e");
    }
  }

  /// ✅ Helper: Prevents a user from registering for multiple roles
  Future<bool> _isAlreadyRegisteredElsewhere(String email, List<String> collections) async {
    for (var col in collections) {
      final query = await _firestore
          .collection(col)
          .where('email', isEqualTo: email)
          .get();
      if (query.docs.isNotEmpty) return true;
    }
    return false;
  }

  /// 🩺 Doctor Selection Logic
  Future<void> handleDoctorSelection(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final email = user.email ?? '';

    // Check if they are already a patient, ambulance, or operator
    if (await _isAlreadyRegisteredElsewhere(email, ['patients', 'ambulances', 'operators'])) {
      _showError(context, "This email is already registered with another role.");
      return;
    }

    final docQuery = await _firestore.collection('doctors').where('email', isEqualTo: email).get();

    if (docQuery.docs.isNotEmpty) {
      final viewModel = DoctorDashboardViewModel(
        userName: user.displayName ?? 'Doctor',
        userEmail: email,
        userPhotoUrl: user.photoURL,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DoctorDashboardScreen(viewModel: viewModel)),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorRegistrationFormScreen(
          userName: user.displayName ?? '',
          userEmail: email,
          userPhotoUrl: user.photoURL,
        ),
      ),
    );
  }

  /// 👤 Patient Selection Logic
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

  /// 🚑 Ambulance Selection Logic
  Future<void> handleAmbulanceSelection(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final email = user.email ?? '';

    if (await _isAlreadyRegisteredElsewhere(email, ['patients', 'doctors', 'operators'])) {
      _showError(context, "This email is registered with another role.");
      return;
    }

    final ambQuery = await _firestore.collection('ambulances').where('email', isEqualTo: email).get();

    if (ambQuery.docs.isNotEmpty) {
      final id = ambQuery.docs.first.id;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("ambulanceId", id);

      // Resume location tracking
      await AmbulanceLocationService.startTracking(id);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AmbulanceDashboardScreen(ambulanceEmail: email)),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AmbulanceRegistrationFormScreen(
          userName: user.displayName ?? '',
          userEmail: email,
        ),
      ),
    );
  }

  /// 🎧 Operator Selection Logic (FIXED)
  Future<void> handleOperatorSelection(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final email = user.email ?? ''; // Variable declared here

    // 1. Cross-role check
    if (await _isAlreadyRegisteredElsewhere(email, ['patients', 'doctors', 'ambulances'])) {
      _showError(context, "This email is registered with another role.");
      return;
    }

    // 2. Check if already exists in operators collection
    final opQuery = await _firestore.collection('operators').where('email', isEqualTo: email).get();

    if (opQuery.docs.isNotEmpty) {
      // ✅ FIXED: Using 'email' variable instead of undefined 'operatorEmail'
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OperatorDashboardScreen(operatorEmail: email),
        ),
      );
      return;
    }

    // 3. New user? Go to registration
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OperatorRegistrationFormScreen(
          userName: user.displayName ?? '',
          userEmail: email,
        ),
      ),
    );
  }

  /// Helper to show SnackBars
  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }
}