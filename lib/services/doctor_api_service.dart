import 'dart:convert';
import 'package:http/http.dart' as http;

class DoctorApiService {
  static const String baseUrl =
      "https://web-production-5d317.up.railway.app";

  static Future<String> predictDisease(String symptoms) async {
    final response = await http.post(
      Uri.parse("$baseUrl/predict"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "symptoms": symptoms, // 🔥 FIXED
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["disease"]; // 🔥 FIXED
    } else {
      throw Exception("Failed to predict disease");
    }
  }
}
