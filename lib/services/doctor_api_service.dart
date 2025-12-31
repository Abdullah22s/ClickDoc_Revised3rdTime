import 'dart:convert';
import 'package:http/http.dart' as http;

class DoctorApiService {
  static const String baseUrl =
      "https://web-production-f4bc.up.railway.app";

  static Future<String> predictSpecialty(String symptoms) async {
    final response = await http.post(
      Uri.parse("$baseUrl/predict"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "text": symptoms,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["specialty"];
    } else {
      throw Exception("Failed to predict specialty");
    }
  }
}
