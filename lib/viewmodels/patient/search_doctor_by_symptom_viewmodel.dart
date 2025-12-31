import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/doctor_api_service.dart';

class SearchDoctorBySymptomViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? predictedSpecialty;
  List<Map<String, dynamic>> matchedDoctors = [];
  List<String> predictedDepartmentMessages = [];

  TextEditingController messageController = TextEditingController();

  /// MAIN FUNCTION: Predict specialty and fetch doctors
  Future<void> predictAndFetchDoctors() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    isLoading = true;
    predictedSpecialty = null;
    matchedDoctors = [];
    predictedDepartmentMessages = [];
    notifyListeners();

    try {
      /// 1️⃣ Call your API to predict specialty
      predictedSpecialty = await DoctorApiService.predictSpecialty(text);

      if (predictedSpecialty == null || predictedSpecialty!.isEmpty) {
        isLoading = false;
        notifyListeners();
        return;
      }

      /// 2️⃣ Fetch all doctors
      final doctorsSnapshot =
      await FirebaseFirestore.instance.collection('doctors').get();

      for (var doc in doctorsSnapshot.docs) {
        final doctorId = doc.id;
        final doctorData = doc.data();

        final doctorEntry = {
          'doctorId': doctorId,
          'doctorName': doctorData['name'] ?? 'Unknown Doctor',
          'departments': <String>{},
        };

        /// Physical OPDs
        final physicalOpds = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorId)
            .collection('physical_opds')
            .get();

        for (var opd in physicalOpds.docs) {
          if (opd['department'] == predictedSpecialty) {
            doctorEntry['departments'].add(opd['department']);
          }
        }

        /// Online Clinics
        final onlineClinics = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorId)
            .collection('online_clinics')
            .get();

        for (var clinic in onlineClinics.docs) {
          if (clinic['department'] == predictedSpecialty) {
            doctorEntry['departments'].add(clinic['department']);
          }
        }

        if ((doctorEntry['departments'] as Set).isNotEmpty) {
          matchedDoctors.add(doctorEntry);
        }
      }

      /// 3️⃣ Generate messages for departments with NO available doctor
      predictedDepartmentMessages = [predictedSpecialty!].map((dept) {
        final doctorExists = matchedDoctors.any(
                (d) => (d['departments'] as Set).contains(dept));
        return doctorExists ? null : "You may consult $dept.";
      }).whereType<String>().toList(); // remove nulls

    } catch (e) {
      print("Error: $e");
      predictedSpecialty = null;
      matchedDoctors = [];
      predictedDepartmentMessages = [];
    }

    isLoading = false;
    notifyListeners();
  }
}
