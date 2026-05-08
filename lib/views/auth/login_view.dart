import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/google_signin_service.dart';
import 'role_selection_view.dart';
import 'package:clickdoc1/views/patient/patient_dashboard_view.dart';
import 'package:clickdoc1/views/doctor/doctor_dashboard_view.dart';
import 'package:clickdoc1/viewmodels/doctor/doctor_dashboard_viewmodel.dart';
import 'package:clickdoc1/views/ambulance/ambulance_dashboard_view.dart';
import 'package:clickdoc1/views/Operator/operator_dashboard_view.dart'; // ✅ Ensure path casing matches your folder

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignInService _googleService = GoogleSignInService();
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);

    try {
      await _googleService.signOut();
      final user = await _googleService.signInWithGoogle();

      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final uid = user.uid;
      final email = user.email ?? ""; // This is the variable we need!
      final name = user.displayName ?? "User";
      final photo = user.photoURL ?? "";

      final firestore = FirebaseFirestore.instance;

      // ✅ Check doctor
      final doctorQuery = await firestore
          .collection('doctors')
          .where('email', isEqualTo: email)
          .get();

      if (doctorQuery.docs.isNotEmpty) {
        final viewModel = DoctorDashboardViewModel(
          userName: name,
          userEmail: email,
          userPhotoUrl: photo,
        );
        _navigateTo(DoctorDashboardScreen(viewModel: viewModel));
        return;
      }

      // ✅ Check ambulance
      final ambulanceQuery = await firestore
          .collection('ambulances')
          .where('email', isEqualTo: email)
          .get();

      if (ambulanceQuery.docs.isNotEmpty) {
        _navigateTo(AmbulanceDashboardScreen(ambulanceEmail: email));
        return;
      }

      // ✅ NEW: Check operator
      final operatorQuery = await firestore
          .collection('operators')
          .where('email', isEqualTo: email)
          .get();

      if (operatorQuery.docs.isNotEmpty) {
        // ✅ FIX: Changed 'operatorEmail: operatorEmail' to 'operatorEmail: email'
        // ✅ FIX: Removed 'const' because 'email' is a dynamic value
        _navigateTo(OperatorDashboardScreen(operatorEmail: email));
        return;
      }

      // ✅ Check patient
      final patientDoc = await firestore.collection('patients').doc(uid).get();
      if (patientDoc.exists) {
        _navigateTo(PatientDashboardScreen(
          userName: patientDoc["name"] ?? name,
          userEmail: email,
          userPhotoUrl: photo,
        ));
        return;
      }

      // ✅ New user → role selection
      _navigateTo(RoleSelectionScreen(userName: name));
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFF90CAF9), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: _isLoading
                ? const CircularProgressIndicator(color: Color(0xFF1565C0))
                : Column(
              children: [
                _buildLogo(),
                const SizedBox(height: 30),
                const Text(
                  'ClickDoc',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0D47A1),
                    letterSpacing: 1.2,
                  ),
                ),
                const Text(
                  'Healthcare at your fingertips',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 60),
                _buildGoogleButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Icons.local_hospital_rounded,
          color: Color(0xFF1565C0), size: 70),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: _handleSignIn,
        icon: Image.network(
          'https://developers.google.com/identity/images/g-logo.png',
          height: 24,
        ),
        label: const Text(
          'Continue with Google',
          style: TextStyle(
              fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}