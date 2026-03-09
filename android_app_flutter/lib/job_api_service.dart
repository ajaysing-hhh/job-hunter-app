import 'dart:convert';

import 'package:http/http.dart' as http;

import 'job_match.dart';

class JobApiService {
  JobApiService(this.baseUrl);

  final String baseUrl;

  Future<List<JobMatch>> fetchMatches() async {
    final uri = Uri.parse('$baseUrl/matches');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Unable to fetch matches: ${response.statusCode}');
    }

    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map((entry) => JobMatch.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> registerPushToken(String token) async {
    final uri = Uri.parse('$baseUrl/register-device');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode >= 400) {
      throw Exception('Unable to register push token');
    }
  }
}
