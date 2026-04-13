import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../views/ambulance/ambulance_dashboard_view.dart';
import '../../services/ambulance_location_service.dart';

class AmbulanceRegistrationViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController serviceNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isLoading = false;

  Future<void> registerAmbulance(
      BuildContext context, String email) async {

    /// ❌ VALIDATION FIRST
    if (serviceNameController.text.isEmpty ||
        phoneController.text.isEmpty) {
      _showMessage(context, 'Please fill all fields');
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      /// 📍 LOCATION PERMISSION
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(context, 'Location permission permanently denied');
        isLoading = false;
        notifyListeners();
        return;
      }

      /// 📍 GET CURRENT LOCATION
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      /// 🚑 SAVE AMBULANCE IN FIRESTORE
      final docRef = await _firestore.collection('ambulances').add({
        "name": serviceNameController.text.trim(),
        "email": email,
        "phone": phoneController.text.trim(),
        "lat": position.latitude,
        "lng": position.longitude,
        "createdAt": FieldValue.serverTimestamp(),
      });

      final ambulanceId = docRef.id;

      /// 💾 STEP 4 FIX: STORE LOCALLY (IMPORTANT FOR BACKGROUND TRACKING)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("ambulanceId", ambulanceId);

      /// 🚑 START LIVE TRACKING (EVERY 30s UPDATE)
      await AmbulanceLocationService.startTracking(ambulanceId);

      _showMessage(context, 'Ambulance Registered Successfully 🚑');

      /// 🚀 NAVIGATE TO DASHBOARD
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AmbulanceDashboardScreen(
            ambulanceEmail: email,
          ),
        ),
      );

    } catch (e) {
      _showMessage(context, 'Error: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  void _showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    serviceNameController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}