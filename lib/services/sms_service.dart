import 'package:http/http.dart' as http;

class SmsService {
  // 🔹 Direct API key (replace with your real key)
  final String apiKey = "ee3c7010a3b059e955c1d1ffd8805e0d27b940ecc4240ca0";

  /// Send SMS to patient
  Future<bool> sendSms({
    required String toNumber,
    required String message,
  }) async {
    final url = Uri.parse(
      'https://api.smsmobileapi.com/sendsms'
          '?apikey=$apiKey'
          '&recipients=${toNumber.replaceAll('+', '')}' // numeric only
          '&message=${Uri.encodeComponent(message)}'
          '&sendsms=1',
    );

    try {
      final response = await http.get(url);

      print('📨 SMS status: ${response.statusCode}');
      print('📨 SMS response: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ SMS exception: $e');
      return false;
    }
  }
}
