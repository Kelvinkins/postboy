import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JsonTreeViewer extends StatelessWidget {
  final dynamic json;

  const JsonTreeViewer({super.key, required this.json});

  @override
  Widget build(BuildContext context) {
    final prettyJson = const JsonEncoder.withIndent('  ').convert(json);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Copy button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: prettyJson));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied JSON to clipboard')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy JSON'),
          ),
        ),

        // Scrollable JSON view
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              scrollDirection: Axis.vertical,
              child: SelectableText.rich(
                _syntaxHighlight(prettyJson),
                style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Syntax highlighting function
  TextSpan _syntaxHighlight(String jsonStr) {
    final List<TextSpan> spans = [];
    final regex = RegExp(
      r'("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|true|false|null|\d+\.?\d*)',
    );
    int lastIndex = 0;

    for (final match in regex.allMatches(jsonStr)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: jsonStr.substring(lastIndex, match.start)));
      }

      final token = match[0]!;

      Color color;
      if (token.startsWith('"')) {
        color = token.endsWith(':') ? Colors.orange : Colors.green;
      } else if (token == 'true' || token == 'false') {
        color = Colors.purple;
      } else if (token == 'null') {
        color = Colors.grey;
      } else {
        color = Colors.blue;
      }

      spans.add(TextSpan(text: token, style: TextStyle(color: color)));
      lastIndex = match.end;
    }

    if (lastIndex < jsonStr.length) {
      spans.add(TextSpan(text: jsonStr.substring(lastIndex)));
    }

    return TextSpan(children: spans);
  }
}
