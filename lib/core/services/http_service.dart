import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/api_request.dart';
import '../models/api_response.dart';

class HttpService {
  final Dio _dio = Dio(
    BaseOptions(
      validateStatus: (status) => true, // Accept all status codes
      responseType: ResponseType.json,
    ),
  );

  Future<ApiResponse> send(ApiRequest request) async {
    try {
      // Decode headers from JSON string if provided
      Map<String, dynamic> resolvedHeaders = {};
      if (request.headers != null && request.headers!.isNotEmpty) {
        try {
          resolvedHeaders = jsonDecode(request.headers!) as Map<String, dynamic>;
        } catch (_) {
          // fallback to empty map
          resolvedHeaders = {};
        }
      }

      final response = await _dio.request(
        request.url,
        data: request.body,
        options: Options(
          method: request.method,
          headers: resolvedHeaders.isNotEmpty ? resolvedHeaders : null,
        ),
      );

      return ApiResponse(
        statusCode: response.statusCode ?? 0,
        data: response.data,
      );
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        data: {'error': e.toString()},
      );
    }
  }
}
