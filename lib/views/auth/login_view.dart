import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/google_signin_service.dart';
import 'role_selection_view.dart';
import 'package:clickdoc1/views/patient/patient_dashboard_view.dart';
import 'package:clickdoc1/views/doctor/doctor_dashboard_view.dart';
import 'package:clickdoc1/viewmodels/doctor/doctor_dashboard_viewmodel.dart';

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
      await _googleService.signOut(); // forces Google account picker
      final user = await _googleService.signInWithGoogle();

      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final uid = user.uid;
      final email = user.email ?? "";
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

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorDashboardScreen(viewModel: viewModel),
          ),
        );
        return;
      }

      // ✅ Check patient
      final patientDoc = await firestore.collection('patients').doc(uid).get();

      if (patientDoc.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PatientDashboardScreen(
              userName: patientDoc["name"] ?? name,
              userEmail: email,
              userPhotoUrl: photo,
            ),
          ),
        );
        return;
      }

      // ✅ New user → role selection
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoleSelectionScreen(userName: name),
        ),
      );
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE3F2FD), // Light blue top
              Color(0xFF90CAF9), // Soft blue middle
              Color(0xFF64B5F6), // Slightly deeper blue bottom
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _isLoading
                ? const CircularProgressIndicator(color: Color(0xFF1565C0))
                : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rounded hospital icon
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Color(0xFF1565C0),
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to ClickDoc',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Book appointments with ease',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _handleSignIn,
                    icon: Image.network(
                      'https://developers.google.com/identity/images/g-logo.png',
                      height: 24,
                    ),
                    label: const Text(
                      'Sign in with Google',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shadowColor: Colors.black.withOpacity(0.15),
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
