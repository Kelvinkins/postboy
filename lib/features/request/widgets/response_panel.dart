import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/json_formatter.dart';
import 'json_viewer.dart';
import 'json_viewer_v2.dart'; // Assuming this contains JsonTreeViewer

class ResponsePanel extends StatelessWidget {
  final dynamic body;
  final int statusCode;
  final Map<String, dynamic>? headers;

  const ResponsePanel({
    super.key,
    required this.body,
    required this.statusCode,
    this.headers,
  });

  /// Normalize body to a JSON string
  String normalizeBody(dynamic body) {
    if (body is String) return body;

    try {
      return jsonEncode(body);
    } catch (_) {
      return body.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Step 1: Normalize body to JSON string
    final rawJsonString = normalizeBody(body);

    // Step 2: Format JSON for readability
    final prettyJson = JsonFormatter.formatJson(rawJsonString);

    // Step 3: Decode JSON safely for tree viewer
    dynamic decoded;
    try {
      decoded = jsonDecode(prettyJson);
    } catch (_) {
      decoded = null; // Not valid JSON, fallback
    }

    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Status & size
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status: $statusCode',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Size: ${rawJsonString.length} bytes'),
                ],
              ),
            ),
            // Tabs
            const TabBar(
              tabs: [
                Tab(text: 'Body'),
                Tab(text: 'Headers'),
                Tab(text: 'Raw'),
              ],
            ),
            // Tab content
            SizedBox(
              height: 600, // adjustable
              child: TabBarView(
                children: [
                  // Body tab (tree viewer)
                  decoded != null
                      ? SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      height: 600, // fixed height
                      child: JsonTreeViewer(json: decoded),
                    ),
                  )
                      : SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Text(rawJsonString),
                  ),

                  // Headers tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: headers != null && headers!.isNotEmpty
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: headers!.entries
                          .map((e) => Text('${e.key}: ${e.value}'))
                          .toList(),
                    )
                        : const Text('No headers'),
                  ),

                  // Raw tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      rawJsonString,
                      style: const TextStyle(fontFamily: 'Courier'),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}
