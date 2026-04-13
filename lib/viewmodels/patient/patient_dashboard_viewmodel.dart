import 'dart:io';
import 'dart:math';

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

  /// 📏 DISTANCE FUNCTION (HAVERSINE)
  double calculateDistance(lat1, lon1, lat2, lon2) {
    const double R = 6371;

    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1 * (pi / 180)) *
                cos(lat2 * (pi / 180)) *
                sin(dLon / 2) *
                sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  /// 🚨 SOS FUNCTION (10KM FILTER APPLIED)
  Future<void> sendEmergencySOS(BuildContext context) async {
    sosLoading = true;
    notifyListeners();

    try {
      /// 📍 Get Patient Location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String? audioUrl;

      /// 🎤 Record Audio
      try {
        if (await _audioRecorder.hasPermission()) {
          final tempDir = await getTemporaryDirectory();
          final fileName =
              'sos_${DateTime.now().millisecondsSinceEpoch}.m4a';
          final path = '${tempDir.path}/$fileName';

          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: path,
          );

          await Future.delayed(const Duration(seconds: 5));

          final finalPath = await _audioRecorder.stop();

          if (finalPath != null) {
            final file = File(finalPath);

            final storageRef = FirebaseStorage.instance
                .ref()
                .child('sos_audio/$fileName');

            await storageRef.putFile(file);

            audioUrl = await storageRef.getDownloadURL();
          }
        }
      } catch (e) {
        debugPrint("Audio error: $e");
      }

      /// 🔍 FIND NEARBY AMBULANCES (<=10KM)
      final snapshot =
      await FirebaseFirestore.instance.collection('ambulances').get();

      List<String> nearbyAmbulances = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        if (data['lat'] != null && data['lng'] != null) {
          double distance = calculateDistance(
            position.latitude,
            position.longitude,
            data['lat'],
            data['lng'],
          );

          if (distance <= 6) {
            nearbyAmbulances.add(doc.id);
          }
        }
      }

      /// 🚨 SEND SOS ONLY TO NEARBY
      await FirebaseFirestore.instance.collection('emergency_requests').add({
        "patientName": patientData?['name'] ?? userName,
        "phone": patientData?['phoneNumber'] ?? userEmail,
        "lat": position.latitude,
        "lng": position.longitude,
        "audioUrl": audioUrl,

        /// ✅ KEY FIELD
        "targetAmbulances": nearbyAmbulances,

        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
        "acceptedBy": null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🚨 SOS sent to nearby ambulances"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("SOS Error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    sosLoading = false;
    notifyListeners();
  }

  List<PatientDashboardModel> get dashboardItems => [
    PatientDashboardModel(
      icon: Icons.warning,
      label: "Emergency SOS",
      gradient: const [Color(0xFFe53935), Color(0xFFe35d5b)],
    ),
  ];
}