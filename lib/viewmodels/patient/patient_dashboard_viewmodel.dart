import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../../services/google_signin_service.dart';
import '../../models/patient/patient_dashboard_model.dart';

class PatientDashboardViewModel extends ChangeNotifier {
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;

  final GoogleSignInService _googleService = GoogleSignInService();

  Map<String, dynamic>? patientData;
  bool isLoading = true;
  bool sosLoading = false;

  final AudioRecorder _audioRecorder = AudioRecorder();

  PatientDashboardViewModel({
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
  }) {
    _loadPatientData();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .where('email', isEqualTo: userEmail)
          .get();

      if (snapshot.docs.isNotEmpty) {
        patientData = snapshot.docs.first.data();
      } else {
        debugPrint("No patient found for email: $userEmail");
      }
    } catch (e) {
      debugPrint("Error loading patient data: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> signOut(BuildContext context) async {
    await _googleService.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  /// ----------------------------------------------------------
  /// 🔹 EMERGENCY SOS (UPDATED WITH 6 KM AMBULANCE FILTER)
  /// ----------------------------------------------------------
  Future<void> sendEmergencySOS(BuildContext context) async {
    sosLoading = true;
    notifyListeners();

    try {
      // 1. Get location first
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String? audioUrl;

      // 2. Audio Recording and Upload
      try {
        if (await _audioRecorder.hasPermission()) {
          final tempDir = await getTemporaryDirectory();
          final fileName =
              'sos_${DateTime.now().millisecondsSinceEpoch}.m4a';
          final path = '${tempDir.path}/$fileName';

          const config = RecordConfig(encoder: AudioEncoder.aacLc);
          await _audioRecorder.start(config, path: path);

          await Future.delayed(const Duration(seconds: 5));
          final finalPath = await _audioRecorder.stop();

          if (finalPath != null) {
            final file = File(finalPath);
            if (await file.exists()) {
              final storageRef = FirebaseStorage.instance
                  .ref()
                  .child('sos_audio/$fileName');

              await storageRef.putFile(
                file,
                SettableMetadata(contentType: 'audio/mp4'),
              );

              await Future.delayed(const Duration(milliseconds: 800));

              audioUrl = await storageRef.getDownloadURL();
            }
          }
        }
      } catch (audioErr) {
        debugPrint("Audio Upload Failed: $audioErr");
      }

      // ----------------------------------------------------------
      // 🚑 NEW: FETCH AMBULANCES + FILTER 6 KM RADIUS
      // ----------------------------------------------------------
      final ambulanceSnapshot = await FirebaseFirestore.instance
          .collection('ambulances')
          .get();

      List<String> nearbyAmbulanceIds = [];
      List<Map<String, dynamic>> nearbyAmbulances = [];

      for (var doc in ambulanceSnapshot.docs) {
        final data = doc.data();

        final double ambLat = data['lat'];
        final double ambLng = data['lng'];

        final double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          ambLat,
          ambLng,
        );

        if (distance <= 3000) {
          nearbyAmbulanceIds.add(doc.id);
          nearbyAmbulances.add({
            "id": doc.id,
            "lat": ambLat,
            "lng": ambLng,
            "distance": distance,
          });
        }
      }

      /// SAVE SOS REQUEST
      await FirebaseFirestore.instance.collection('emergency_requests').add({
        "patientName": patientData?['name'] ?? userName,
        "phone": patientData?['phoneNumber'] ?? userEmail,
        "lat": position.latitude,
        "lng": position.longitude,
        "audioUrl": audioUrl,
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
        "acceptedBy": null,

        // ✅ NEW: nearby ambulances only
        "nearbyAmbulances": nearbyAmbulanceIds,
        "nearbyAmbulanceDetails": nearbyAmbulances,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🚨 Emergency SOS sent successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Full SOS Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Critical Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      sosLoading = false;
      notifyListeners();
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
      icon: Icons.warning_amber_rounded,
      label: "Emergency SOS",
      gradient: const [Color(0xFFe53935), Color(0xFFe35d5b)],
    ),
  ];
}