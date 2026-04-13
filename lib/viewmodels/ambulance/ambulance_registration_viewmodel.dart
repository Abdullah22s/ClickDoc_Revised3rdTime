import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../../views/ambulance/ambulance_dashboard_view.dart';

class AmbulanceRegistrationViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController serviceNameController =
  TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isLoading = false;

  Future<void> registerAmbulance(
      BuildContext context, String email) async {
    if (serviceNameController.text.isEmpty ||
        phoneController.text.isEmpty) {
      _showMessage(context, 'Please fill all fields');
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      /// 📍 Get Location Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      /// 📍 Get Current Location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _firestore.collection('ambulances').add({
        "name": serviceNameController.text.trim(),
        "email": email,
        "phone": phoneController.text.trim(),

        /// ✅ LOCATION SAVED
        "lat": position.latitude,
        "lng": position.longitude,

        "createdAt": Timestamp.now(),
      });

      _showMessage(context, 'Ambulance Registered Successfully');

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