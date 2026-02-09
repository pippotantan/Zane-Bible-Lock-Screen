import 'dart:convert';
import 'package:http/http.dart' as http;

class UnsplashService {
  static const String _accessKey = '-rS9QoE7QcKbk7JxliDlg4g-5AxfASbXa0G2gk-CPKI';

  static const String _endpoint =
      'https://api.unsplash.com/photos/random'
      '?orientation=portrait'
      '&query=nature,faith,sky,landscape'
      '&content_filter=high';

  Future<String> fetchRandomBackground() async {
    final response = await http.get(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Client-ID $_accessKey',
      },
    );

    if (response.statusCode != 200 || response.body.isEmpty) {
      throw Exception('Failed to load Unsplash image');
    }

    final data = jsonDecode(response.body);
    return data['urls']['regular'];
  }
}