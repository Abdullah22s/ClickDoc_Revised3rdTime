import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/doctor_api_service.dart';

class SearchDoctorBySymptomViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? predictedSpecialty;

  /// Each item will contain:
  /// {
  ///   doctorId,
  ///   doctorName,
  ///   hasOnline,
  ///   hasPhysical
  /// }
  List<Map<String, dynamic>> matchedDoctors = [];

  /// Used if no doctor is found
  List<String> predictedDepartmentMessages = [];

  /// Dropdown selection per doctor
  final Map<String, String> selectedClinicType = {};

  TextEditingController messageController = TextEditingController();

  /// MAIN FUNCTION
  Future<void> predictAndFetchDoctors() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    isLoading = true;
    predictedSpecialty = null;
    matchedDoctors.clear();
    predictedDepartmentMessages.clear();
    selectedClinicType.clear();
    notifyListeners();

    try {
      /// 1️⃣ Predict specialty
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

        bool hasOnline = false;
        bool hasPhysical = false;

        /// 🔹 CHECK PHYSICAL OPDs
        final physicalSnap = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorId)
            .collection('physical_opds')
            .where('department', isEqualTo: predictedSpecialty)
            .limit(1)
            .get();

        if (physicalSnap.docs.isNotEmpty) {
          hasPhysical = true;
        }

        /// 🔹 CHECK ONLINE CLINICS
        final onlineSnap = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorId)
            .collection('online_clinics')
            .where('department', isEqualTo: predictedSpecialty)
            .limit(1)
            .get();

        if (onlineSnap.docs.isNotEmpty) {
          hasOnline = true;
        }

        /// 🔹 ADD DOCTOR IF ANY MATCH FOUND
        if (hasOnline || hasPhysical) {
          matchedDoctors.add({
            'doctorId': doctorId,
            'doctorName': doctorData['name'] ?? 'Unknown Doctor',
            'hasOnline': hasOnline,
            'hasPhysical': hasPhysical,
          });
        }
      }

      /// 3️⃣ MESSAGE IF NO DOCTOR FOUND
      if (matchedDoctors.isEmpty) {
        predictedDepartmentMessages
            .add("You may consult $predictedSpecialty.");
      }
    } catch (e) {
      debugPrint("SearchDoctorBySymptom error: $e");
      predictedSpecialty = null;
      matchedDoctors.clear();
      predictedDepartmentMessages.clear();
    }

    isLoading = false;
    notifyListeners();
  }
}
