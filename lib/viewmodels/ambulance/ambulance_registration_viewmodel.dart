import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../views/ambulance/ambulance_dashboard_view.dart'; // ✅ NEW

class AmbulanceRegistrationViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController serviceNameController =
  TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isLoading = false;

  /// 🚑 Register Ambulance (WITHOUT LOCATION)
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
      await _firestore.collection('ambulances').add({
        "name": serviceNameController.text.trim(),
        "email": email,
        "phone": phoneController.text.trim(),
        "createdAt": Timestamp.now(),
      });

      _showMessage(context, 'Ambulance Registered Successfully');

      /// ✅ NEW: Redirect to Dashboard
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