import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://november7-730026606190.europe-west1.run.app';

  static Future<String> fetchRandomImage() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/image'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['url'] != null && data['url'].isNotEmpty) {
          return data['url'];
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching image: $e');
    }
  }
}
