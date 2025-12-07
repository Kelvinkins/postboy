import 'dart:convert';

class JsonFormatter {
  /// Formats a JSON string with indentation.
  /// If the input is not valid JSON, returns it raw.
  static String formatJson(String input) {
    try {
      // Parse JSON
      final dynamic jsonObject = json.decode(input);

      // Pretty-print with indentation
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(jsonObject);
    } catch (_) {
      // Not valid JSON, return raw
      return input;
    }
  }
}
