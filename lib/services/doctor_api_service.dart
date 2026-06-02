import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DiseasePredictionResult {
  final String status;
  final String message;
  final String disease;
  final String modelDisease;
  final double confidencePercent;
  final String assurityLevel;
  final bool aiUsed;
  final String source;
  final String note;
  final String disclaimer;

  DiseasePredictionResult({
    required this.status,
    required this.message,
    required this.disease,
    required this.modelDisease,
    required this.confidencePercent,
    required this.assurityLevel,
    required this.aiUsed,
    required this.source,
    required this.note,
    required this.disclaimer,
  });

  factory DiseasePredictionResult.fromJson(Map<String, dynamic> json) {
    return DiseasePredictionResult(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      disease: json['disease']?.toString() ?? '',
      modelDisease: json['model_disease']?.toString() ?? '',
      confidencePercent:
      double.tryParse(json['confidence_percent']?.toString() ?? '0') ?? 0.0,
      assurityLevel: json['assurity_level']?.toString() ?? '',
      aiUsed: json['ai_used'] == true,
      source: json['source']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      disclaimer: json['disclaimer']?.toString() ??
          'This is an AI-assisted prediction, not a final medical diagnosis. Please consult a doctor for confirmation.',
    );
  }
}

class DoctorApiService {
  static const String baseUrl = "https://web-production-277f6.up.railway.app";

  static Future<DiseasePredictionResult?> predictDiseaseFull(
      String symptoms) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/predict"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "symptoms": symptoms,
        }),
      );

      debugPrint("Predict API status: ${response.statusCode}");
      debugPrint("Predict API response: ${response.body}");

      if (response.statusCode != 200) {
        return DiseasePredictionResult(
          status: "error",
          message: "Server error. Please try again.",
          disease: "",
          modelDisease: "",
          confidencePercent: 0,
          assurityLevel: "",
          aiUsed: false,
          source: "",
          note: "",
          disclaimer: "",
        );
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      return DiseasePredictionResult.fromJson(data);
    } catch (e) {
      debugPrint("DoctorApiService predictDiseaseFull error: $e");

      return DiseasePredictionResult(
        status: "error",
        message: "Unable to connect to prediction server.",
        disease: "",
        modelDisease: "",
        confidencePercent: 0,
        assurityLevel: "",
        aiUsed: false,
        source: "",
        note: e.toString(),
        disclaimer: "",
      );
    }
  }

  // Keep this old method so other existing code does not break.
  static Future<String?> predictDisease(String symptoms) async {
    final result = await predictDiseaseFull(symptoms);

    if (result == null) return null;

    if (result.status == "success") {
      return result.disease;
    }

    return null;
  }
}