class ApiResponse {
  final int statusCode;
  final dynamic data;
  final Map<String, String>? headers; // add this


  ApiResponse({required this.statusCode, required this.data, this.headers});
}
