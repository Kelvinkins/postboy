import 'dart:convert';
import 'package:flutter/material.dart';

class JsonEditorField extends StatefulWidget {
  final TextEditingController controller;

  const JsonEditorField({super.key, required this.controller});

  @override
  State<JsonEditorField> createState() => _JsonEditorFieldState();
}

class _JsonEditorFieldState extends State<JsonEditorField> {
  String? error;

  void _validate(String text) {
    try {
      if (text.trim().isEmpty) {
        setState(() => error = null);
        return;
      }

      jsonDecode(text);
      setState(() => error = null);
    } catch (e) {
      setState(() => error = "Invalid JSON");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.controller,
          maxLines: 10,
          onChanged: _validate,
          style: const TextStyle(fontFamily: "monospace"),
          decoration: InputDecoration(
            labelText: "JSON Body",
            errorText: error,
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
