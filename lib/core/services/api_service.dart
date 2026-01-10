import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/result.dart';

/// Service untuk HTTP requests ke API backend
class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Future<Result<T>> _handleRequest<T>(
    Future<http.Response> Function() request,
    T Function(dynamic json) parser,
  ) async {
    try {
      final response = await request().timeout(
        Duration(seconds: ApiConfig.timeoutSeconds),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return Success(null as T);
        }
        final json = jsonDecode(response.body);
        return Success(parser(json));
      } else {
        String errorMsg = 'Request failed';
        try {
          final error = jsonDecode(response.body);
          errorMsg = error['error'] ?? 'Request failed';
        } catch (_) {}
        return Failure(errorMsg, code: response.statusCode.toString());
      }
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// GET request
  Future<Result<T>> get<T>(
    String path,
    T Function(dynamic json) parser, {
    Map<String, String>? queryParams,
  }) async {
    return _handleRequest(
      () =>
          _client.get(_buildUri(path, queryParams), headers: ApiConfig.headers),
      parser,
    );
  }

  /// POST request
  Future<Result<T>> post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic json) parser,
  ) async {
    return _handleRequest(
      () => _client.post(
        _buildUri(path),
        headers: ApiConfig.headers,
        body: jsonEncode(body),
      ),
      parser,
    );
  }

  /// PUT request
  Future<Result<T>> put<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic json) parser,
  ) async {
    return _handleRequest(
      () => _client.put(
        _buildUri(path),
        headers: ApiConfig.headers,
        body: jsonEncode(body),
      ),
      parser,
    );
  }

  /// PATCH request
  Future<Result<T>> patch<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic json) parser,
  ) async {
    return _handleRequest(
      () => _client.patch(
        _buildUri(path),
        headers: ApiConfig.headers,
        body: jsonEncode(body),
      ),
      parser,
    );
  }

  /// DELETE request
  Future<Result<void>> delete(String path) async {
    return _handleRequest<void>(
      () => _client.delete(_buildUri(path), headers: ApiConfig.headers),
      (_) {},
    );
  }

  void dispose() {
    _client.close();
  }
}
