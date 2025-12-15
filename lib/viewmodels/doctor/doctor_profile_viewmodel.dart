import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/doctor/doctor_profile_model.dart';

class DoctorProfileViewModel extends ChangeNotifier {
  final String userEmail;
  bool loading = true;
  DoctorProfileModel? doctorProfile;

  DoctorProfileViewModel({required this.userEmail}) {
    loadDoctorProfile();
  }

  Future<void> loadDoctorProfile() async {
    loading = true;
    notifyListeners();

    try {
      final query = await FirebaseFirestore.instance
          .collection('doctors')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        doctorProfile = DoctorProfileModel.fromMap(data);
      }
    } catch (e) {
      debugPrint("Error fetching doctor profile: $e");
    }

    loading = false;
    notifyListeners();
  }
}
