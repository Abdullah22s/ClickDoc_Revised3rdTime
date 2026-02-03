import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/doctor_api_service.dart';
import '../../utils/disease_department_mapper.dart';

class SearchDoctorBySymptomViewModel extends ChangeNotifier {
  bool isLoading = false;

  String? predictedDisease;
  String? predictedDepartment;

  List<Map<String, dynamic>> matchedDoctors = [];
  List<String> predictedDepartmentMessages = [];

  final Map<String, String> selectedClinicType = {};
  TextEditingController messageController = TextEditingController();

  /// 🔑 OPENAI KEY (⚠️ MOVE TO BACKEND IN PRODUCTION)
  static const String _openAiApiKey = "Open_api_key";

  /// ===============================
  /// 🤖 ChatGPT Validation
  /// ===============================
  Future<bool> _isValidSymptomUsingAI(String text) async {
    try {
      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $_openAiApiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content":
              "You are a medical input validator. Reply ONLY with YES or NO."
            },
            {
              "role": "user",
              "content":
              "Is the following text a meaningful symptom written in English or Urdu? Text: \"$text\""
            }
          ],
          "temperature": 0,
          "max_tokens": 5,
        }),
      );

      if (response.statusCode != 200) return false;

      final content =
      jsonDecode(response.body)['choices'][0]['message']['content']
          .toString()
          .toUpperCase();

      return content.contains("YES");
    } catch (e) {
      debugPrint("AI validation error: $e");
      return false;
    }
  }

  /// ===============================
  /// 🩺 Predict Disease & Fetch Doctors
  /// ===============================
  Future<void> predictAndFetchDoctors() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    isLoading = true;
    predictedDisease = null;
    predictedDepartment = null;
    matchedDoctors.clear();
    predictedDepartmentMessages.clear();
    selectedClinicType.clear();
    notifyListeners();

    /// 🤖 STEP 1: AI VALIDATION
    final isValid = await _isValidSymptomUsingAI(text);

    if (!isValid) {
      isLoading = false;

      predictedDepartmentMessages.add(
        "Please enter a valid symptom in English or Urdu.",
      );

      notifyListeners();
      return;
    }

    try {
      /// 2️⃣ Predict disease (your backend)
      predictedDisease =
      await DoctorApiService.predictDisease(text);

      if (predictedDisease == null || predictedDisease!.isEmpty) {
        isLoading = false;
        notifyListeners();
        return;
      }

      /// 3️⃣ Map disease → department
      predictedDepartment =
          mapDiseaseToDepartment(predictedDisease!);

      /// 4️⃣ Fetch doctors
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

        if (physicalSnap.docs.isNotEmpty) hasPhysical = true;

        final onlineSnap = await FirebaseFirestore.instance
            .collection('doctors')
            .doc(doctorId)
            .collection('online_clinics')
            .where('department', isEqualTo: predictedDepartment)
            .limit(1)
            .get();

        if (onlineSnap.docs.isNotEmpty) hasOnline = true;

        if (hasOnline || hasPhysical) {
          matchedDoctors.add({
            'doctorId': doctorId,
            'doctorName': doctorData['name'] ?? 'Unknown Doctor',
            'hasOnline': hasOnline,
            'hasPhysical': hasPhysical,
          });
        }
      }

      if (matchedDoctors.isEmpty &&
          predictedDepartment != null) {
        predictedDepartmentMessages.add(
          "You may consult $predictedDepartment.",
        );
      }
    } catch (e) {
      debugPrint("SearchDoctorBySymptom error: $e");
      predictedDisease = null;
      predictedDepartment = null;
      matchedDoctors.clear();
    }

    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}
