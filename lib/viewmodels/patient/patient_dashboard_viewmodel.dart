import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/google_signin_service.dart';
import '../../models/patient/patient_dashboard_model.dart';

class PatientDashboardViewModel extends ChangeNotifier {
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;

  final GoogleSignInService _googleService = GoogleSignInService();

  Map<String, dynamic>? patientData;
  bool isLoading = true;

  PatientDashboardViewModel({
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
  }) {
    _loadPatientData();
  }

  /// ----------------------------------------------------------
  /// 🔹 LOAD PATIENT INFORMATION FROM FIRESTORE
  /// ----------------------------------------------------------
  Future<void> _loadPatientData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(userEmail)
          .get();

      if (doc.exists) {
        patientData = doc.data();
      }
    } catch (e) {
      debugPrint("Error loading patient data: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  /// ----------------------------------------------------------
  /// 🔹 SIGN OUT LOGIC
  /// ----------------------------------------------------------
  Future<void> signOut(BuildContext context) async {
    await _googleService.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  List<PatientDashboardModel> get dashboardItems => [
    PatientDashboardModel(
      icon: Icons.person,
      label: "My Profile",
      gradient: const [Color(0xFF6A11CB), Color(0xFF2575FC)],
    ),
    PatientDashboardModel(
      icon: Icons.local_hospital,
      label: "Physical OPDs",
      gradient: const [Color(0xFF4CA1AF), Color(0xFFC4E0E5)],
    ),
    PatientDashboardModel(
      icon: Icons.video_call,
      label: "Online Doctors",
      gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
    ),
    PatientDashboardModel(
      icon: Icons.psychology,
      label: "Search by Symptom",
      gradient: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    ),
    PatientDashboardModel(
      icon: Icons.bloodtype,
      label: "Blood Bank",
      gradient: const [Color(0xFFF7971E), Color(0xFFFFD200)],
    ),
    PatientDashboardModel(
      icon: Icons.medical_services,
      label: "Appointments",
      gradient: const [Color(0xFF00C6FF), Color(0xFF0072FF)],
    ),
  ];
}
