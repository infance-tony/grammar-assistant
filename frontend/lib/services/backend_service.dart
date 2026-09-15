import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/action_result.dart';

/// HTTP client that communicates with the local FastAPI backend.
class BackendService {
  static const String _baseUrl = 'http://127.0.0.1:11434';
  static const Duration _timeout = Duration(seconds: 120);

  static final BackendService _instance = BackendService._();
  static BackendService get instance => _instance;
  BackendService._();

  /// Checks if the backend is ready to accept requests.
  Future<bool> isHealthy() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['status'] == 'ready';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Sends text to the backend for processing.
  Future<ActionResult> processText({
    required String action,
    required String text,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/process'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'action': action, 'text': text}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ActionResult.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw BackendException(
          'Server error ${response.statusCode}: ${error['detail'] ?? 'Unknown error'}',
        );
      }
    } on SocketException {
      throw BackendException(
        'Cannot connect to the AI service. Make sure the backend is running.',
      );
    } on http.ClientException catch (e) {
      throw BackendException('Network error: ${e.message}');
    }
  }

  /// Returns the list of available GGUF model filenames and the active model name.
  Future<Map<String, dynamic>> getModels() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/models'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw BackendException('Failed to list models: ${response.statusCode}');
    } on SocketException {
      throw BackendException('Cannot connect to the AI service.');
    }
  }

  /// Switches the active model. Model reload can take 10–30 seconds.
  Future<void> switchModel(String filename) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/switch_model'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'filename': filename}),
          )
          .timeout(const Duration(seconds: 90));
      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw BackendException(
          'Model switch failed: ${error['detail'] ?? 'Unknown error'}',
        );
      }
    } on SocketException {
      throw BackendException('Cannot connect to the AI service.');
    }
  }
}

/// Exception thrown when the backend returns an error or is unreachable.
class BackendException implements Exception {
  final String message;
  const BackendException(this.message);

  @override
  String toString() => message;
}
