import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/doctor_api_service.dart';
import '../../utils/disease_department_mapper.dart';

class SearchDoctorBySymptomViewModel extends ChangeNotifier {
  bool isLoading = false;

  String? predictedDisease;
  String? predictedDepartment;

  String? modelDisease;
  double? predictionConfidence;
  String? predictionAssurityLevel;
  bool aiUsed = false;
  String? predictionSource;
  String? predictionNote;
  String? predictionDisclaimer;

  List<Map<String, dynamic>> matchedDoctors = [];
  List<String> predictedDepartmentMessages = [];

  final Map<String, String> selectedClinicType = {};
  TextEditingController messageController = TextEditingController();

  Future<void> predictAndFetchDoctors() async {
    final text = messageController.text.trim();

    if (text.isEmpty) {
      predictedDepartmentMessages.clear();
      predictedDepartmentMessages.add("Please enter your symptoms.");
      notifyListeners();
      return;
    }

    if (text.length < 3) {
      predictedDepartmentMessages.clear();
      predictedDepartmentMessages.add("Please enter valid symptoms.");
      notifyListeners();
      return;
    }

    isLoading = true;

    predictedDisease = null;
    predictedDepartment = null;
    modelDisease = null;
    predictionConfidence = null;
    predictionAssurityLevel = null;
    aiUsed = false;
    predictionSource = null;
    predictionNote = null;
    predictionDisclaimer = null;

    matchedDoctors.clear();
    predictedDepartmentMessages.clear();
    selectedClinicType.clear();

    notifyListeners();

    try {
      final predictionResult =
      await DoctorApiService.predictDiseaseFull(text);

      if (predictionResult == null) {
        predictedDepartmentMessages.add(
          "Unable to connect to prediction server. Please try again.",
        );
        return;
      }

      if (predictionResult.status == "invalid") {
        predictedDepartmentMessages.add(
          predictionResult.message.isNotEmpty
              ? predictionResult.message
              : "Please enter valid medical symptoms.",
        );
        return;
      }

      if (predictionResult.status != "success") {
        predictedDepartmentMessages.add(
          predictionResult.message.isNotEmpty
              ? predictionResult.message
              : "Unable to predict disease. Please try again.",
        );
        return;
      }

      predictedDisease = predictionResult.disease;
      modelDisease = predictionResult.modelDisease;
      predictionConfidence = predictionResult.confidencePercent;
      predictionAssurityLevel = predictionResult.assurityLevel;
      aiUsed = predictionResult.aiUsed;
      predictionSource = predictionResult.source;
      predictionNote = predictionResult.note;
      predictionDisclaimer = predictionResult.disclaimer;

      if (predictedDisease == null || predictedDisease!.trim().isEmpty) {
        predictedDepartmentMessages.add(
          "Unable to predict disease. Please try again.",
        );
        return;
      }

      predictedDepartment = _getDepartmentForDisease(predictedDisease!);

      predictedDepartmentMessages.add(
        "Predicted disease: $predictedDisease",
      );

      if (modelDisease != null &&
          modelDisease!.isNotEmpty &&
          modelDisease != predictedDisease) {
        predictedDepartmentMessages.add(
          "Model prediction was $modelDisease, corrected by AI assistance.",
        );
      }

      if (predictionConfidence != null) {
        predictedDepartmentMessages.add(
          "Confidence: ${predictionConfidence!.toStringAsFixed(2)}% ($predictionAssurityLevel)",
        );
      }

      if (aiUsed) {
        predictedDepartmentMessages.add(
          "AI assistance was used because model confidence was low/medium.",
        );
      }

      if (predictionNote != null && predictionNote!.trim().isNotEmpty) {
        predictedDepartmentMessages.add(predictionNote!);
      }

      if (predictionDisclaimer != null &&
          predictionDisclaimer!.trim().isNotEmpty) {
        predictedDepartmentMessages.add(predictionDisclaimer!);
      }

      await _fetchMatchedDoctors();
    } catch (e) {
      debugPrint("SearchDoctorBySymptom error: $e");

      predictedDisease = null;
      predictedDepartment = null;
      matchedDoctors.clear();

      predictedDepartmentMessages.add(
        "Something went wrong. Please try again.",
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _getDepartmentForDisease(String disease) {
    try {
      final department = mapDiseaseToDepartment(disease).trim();

      if (department.isNotEmpty &&
          department.toLowerCase() != "unknown" &&
          department.toLowerCase() != "null") {
        return department;
      }
    } catch (e) {
      debugPrint("Disease department mapping error: $e");
    }

    // Change this only if your Firestore uses another exact department name.
    return "General Physician";
  }

  Future<void> _fetchMatchedDoctors() async {
    if (predictedDepartment == null || predictedDepartment!.isEmpty) {
      return;
    }

    final doctorsSnapshot =
    await FirebaseFirestore.instance.collection('doctors').get();

    for (var doc in doctorsSnapshot.docs) {
      final doctorId = doc.id;
      final doctorData = doc.data();

      bool hasOnline = false;
      bool hasPhysical = false;

      final physicalSnap = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .collection('physical_opds')
          .where('department', isEqualTo: predictedDepartment)
          .limit(1)
          .get();

      if (physicalSnap.docs.isNotEmpty) {
        hasPhysical = true;
      }

      final onlineSnap = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .collection('online_clinics')
          .where('department', isEqualTo: predictedDepartment)
          .limit(1)
          .get();

      if (onlineSnap.docs.isNotEmpty) {
        hasOnline = true;
      }

      if (hasOnline || hasPhysical) {
        matchedDoctors.add({
          'doctorId': doctorId,
          'doctorName': doctorData['name'] ?? 'Unknown Doctor',
          'hasOnline': hasOnline,
          'hasPhysical': hasPhysical,
        });
      }
    }

    if (matchedDoctors.isEmpty && predictedDepartment != null) {
      predictedDepartmentMessages.add(
        "You may consult $predictedDepartment.",
      );
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}