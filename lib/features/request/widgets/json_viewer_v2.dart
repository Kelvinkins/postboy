import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JsonTreeViewer1 extends StatefulWidget {
  final String payload;

  const JsonTreeViewer1({super.key, required this.payload});

  @override
  State<JsonTreeViewer1> createState() => _JsonTreeViewerState();
}

class _JsonTreeViewerState extends State<JsonTreeViewer1> {
  final Map<String, bool> expandedMap = {};
  dynamic decoded;

  @override
  void initState() {
    super.initState();

    try {
      if (widget.payload.trim().startsWith("{") ||
          widget.payload.trim().startsWith("[")) {
        decoded = normalizeJson(json.decode(widget.payload));
      } else {
        decoded = widget.payload;
      }
    } catch (_) {
      decoded = widget.payload;
    }
  }

  /// ---- FIX: Convert all Maps into Map<String, dynamic> ----
  dynamic normalizeJson(dynamic input) {
    if (input is Map) {
      return input.map(
            (key, value) => MapEntry(key.toString(), normalizeJson(value)),
      );
    } else if (input is List) {
      return input.map(normalizeJson).toList();
    }
    return input;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(context),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: _buildRoot(),
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Payload", style: TextStyle(fontSize: 16)),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () {
            Clipboard.setData(
              ClipboardData(
                text: const JsonEncoder.withIndent("  ").convert(decoded),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Copied full payload")),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRoot() {
    if (decoded is Map<String, dynamic>) {
      return _jsonObjectNode("/", decoded as Map<String, dynamic>, 0);
    } else if (decoded is List) {
      return _jsonArrayNode("/", decoded as List<dynamic>, 0);
    } else {
      return _primitiveNode(null, decoded, 0);
    }
  }

  Widget _jsonObjectNode(
      String path, Map<String, dynamic> obj, int level) {
    final isExpanded = expandedMap[path] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _nodeHeader(
          path: path,
          level: level,
          isExpanded: isExpanded,
          openChar: "{",
          closeChar: "}",
          onCopy: () {
            Clipboard.setData(
              ClipboardData(
                text: const JsonEncoder.withIndent("  ").convert(obj),
              ),
            );
          },
        ),
        if (isExpanded)
          ...obj.entries.map((entry) {
            final childPath = "$path.${entry.key}";
            final value = entry.value;

            if (value is Map<String, dynamic>) {
              return _jsonObjectNode(childPath, value, level + 1);
            } else if (value is List) {
              return _jsonArrayNode(childPath, value, level + 1);
            }
            return _primitiveNode(entry.key, value, level + 1);
          }),
        Padding(
          padding: EdgeInsets.only(left: level * 12.0),
          child: const Text("}", style: TextStyle(fontFamily: "monospace")),
        ),
      ],
    );
  }

  Widget _jsonArrayNode(String path, List array, int level) {
    final isExpanded = expandedMap[path] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _nodeHeader(
          path: path,
          level: level,
          isExpanded: isExpanded,
          openChar: "[",
          closeChar: "]",
          onCopy: () {
            Clipboard.setData(
              ClipboardData(
                text: const JsonEncoder.withIndent("  ").convert(array),
              ),
            );
          },
        ),
        if (isExpanded)
          ...List.generate(array.length, (i) {
            final childPath = "$path.$i";
            final value = array[i];

            if (value is Map<String, dynamic>) {
              return _jsonObjectNode(childPath, value, level + 1);
            } else if (value is List) {
              return _jsonArrayNode(childPath, value, level + 1);
            }
            return _primitiveNode(i.toString(), value, level + 1);
          }),
        Padding(
          padding: EdgeInsets.only(left: level * 12.0),
          child: const Text("]", style: TextStyle(fontFamily: "monospace")),
        ),
      ],
    );
  }

  Widget _primitiveNode(String? key, dynamic value, int level) {
    final displayValue = value is String ? "\"$value\"" : value.toString();

    return Padding(
      padding: EdgeInsets.only(left: level * 12.0, top: 4, bottom: 4),
      child: Row(
        children: [
          if (key != null)
            Text("\"$key\": ",
                style: const TextStyle(fontFamily: "monospace")),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(fontFamily: "monospace"),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: displayValue));
            },
          )
        ],
      ),
    );
  }

  Widget _nodeHeader({
    required String path,
    required int level,
    required bool isExpanded,
    required String openChar,
    required String closeChar,
    required VoidCallback onCopy,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: level * 12.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_right,
            ),
            onPressed: () {
              setState(() {
                expandedMap[path] = !isExpanded;
              });
            },
            constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
            padding: EdgeInsets.zero,
          ),
          Expanded(
            child: Text(
              openChar,
              style: const TextStyle(fontFamily: "monospace"),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: onCopy,
          )
        ],
      ),
    );
  }
}
