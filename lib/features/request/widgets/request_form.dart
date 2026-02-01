import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/models/api_request.dart';
import '../../../core/models/environment.dart';
import '../../../data/request_repository.dart';
import '../bloc/request_bloc.dart';
import '../bloc/request_event.dart';
import '../../../core/db/database_helper.dart';
import '../bloc/request_state.dart';
import 'json_editor.dart';

class RequestForm extends StatefulWidget {
  final RequestBloc bloc;
  final bool isPro;

  const RequestForm({super.key, required this.bloc, required this.isPro});

  @override
  State<RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<RequestForm> {
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final GenericRepository<Environment> repo = GenericRepository(
      tableName: "environments", fromJson: (json) => Environment.fromJson(json));

  String _authType = 'None';
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _customHeaderKeyCtrl = TextEditingController();
  final _customHeaderValueCtrl = TextEditingController();

  final List<String> _contentTypeOptions = [
    'application/json',
    'application/x-www-form-urlencoded',
    'text/plain',
    'multipart/form-data',
    'Custom'
  ];
  String _contentType = 'application/json';
  final _customContentTypeCtrl = TextEditingController();

  String _method = 'GET';
  bool _isLoading = false;

  List<Map<String, dynamic>> _environments = [];
  int? _selectedEnvironmentId;

  @override
  void initState() {
    super.initState();
    _loadEnvironments();
  }

  Future<void> _loadEnvironments() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('environments', orderBy: 'name ASC');
    setState(() {
      _environments = result;
      if (_environments.isNotEmpty) {
        _selectedEnvironmentId = _environments.first['id'] as int;
      }
    });
  }

  Future<void> _sendAndSave(bool isPro) async {
    if (_nameCtrl.text.isEmpty || _urlCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and URL cannot be empty')),
      );
      return;
    }

    final headers = await _buildHeaders(isPro);

    final req = ApiRequest(
        name: _nameCtrl.text.trim(),
        url: _urlCtrl.text.trim(),
        method: _method,
        headers: headers != null ? jsonEncode(headers) : null,
        body: _bodyCtrl.text.isNotEmpty ? _bodyCtrl.text : null,
        environmentId: _selectedEnvironmentId,
        authType: _authType,
        username: _usernameCtrl.text,
        password: _passwordCtrl.text,
        token: _tokenCtrl.text,
        customHeaderKey: _customHeaderKeyCtrl.text,
        customHeaderValue: _customHeaderValueCtrl.text,
        contentType: ""
    );

    widget.bloc.add(AddRequest(req));
    widget.bloc.add(SendRequest(req));

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  Future<Map<String, String>?> _buildHeaders(bool isPro) async {
    Map<String, String>? headers;
    if (isPro && _selectedEnvironmentId != null) {
      headers = await _buildHeadersFromRepo(_selectedEnvironmentId!);
    } else {
      headers = _buildHeadersFromDropdown();
    }

    final contentTypeValue = _contentType == 'Custom'
        ? _customContentTypeCtrl.text.trim()
        : _contentType;

    if (contentTypeValue.isNotEmpty) {
      headers ??= <String, String>{};
      headers['Content-Type'] = contentTypeValue;
    }

    return headers;
  }

  Future<Map<String, String>?> _buildHeadersFromRepo(int id) async {
    final e = await repo.getById(id);
    final env = e?.toJson();
    if (env == null) return null;

    final headers = <String, String>{};
    final authType = env['auth_type'] as String?;

    switch (authType) {
      case 'Basic':
        final basic =
        base64Encode(utf8.encode('${env['username']}:${env['password']}'));
        headers["Authorization"] = "Basic $basic";
        break;
      case 'Bearer Token':
        headers["Authorization"] = "Bearer ${env['token']}";
        break;
      case 'Custom Header':
        final key = env['custom_header_key']?.toString() ?? '';
        final value = env['custom_header_value']?.toString() ?? '';
        if (key.isNotEmpty) headers[key] = value;
        break;
      default:
        break;
    }

    return headers.isEmpty ? null : headers;
  }

  Map<String, String>? _buildHeadersFromDropdown() {
    final headers = <String, String>{};

    switch (_authType) {
      case 'Basic':
        final basic = base64Encode(
            utf8.encode('${_usernameCtrl.text}:${_passwordCtrl.text}'));
        headers["Authorization"] = "Basic $basic";
        break;
      case 'Bearer Token':
        headers["Authorization"] = "Bearer ${_tokenCtrl.text}";
        break;
      case 'Custom Header':
        final key = _customHeaderKeyCtrl.text.trim();
        final value = _customHeaderValueCtrl.text;
        if (key.isNotEmpty) headers[key] = value;
        break;
      default:
        break;
    }

    return headers.isEmpty ? null : headers;
  }

  void _loadAuthFromHeaders(String? headersJson) {
    _usernameCtrl.clear();
    _passwordCtrl.clear();
    _tokenCtrl.clear();
    _customHeaderKeyCtrl.clear();
    _customHeaderValueCtrl.clear();
    _authType = "None";

    _contentType = 'application/json';
    _customContentTypeCtrl.clear();

    if (headersJson == null || headersJson.isEmpty) return;

    final headers = jsonDecode(headersJson) as Map<String, dynamic>;

    if (headers.containsKey("Authorization")) {
      final auth = headers["Authorization"] as String;
      if (auth.startsWith("Basic ")) {
        _authType = "Basic";
        final decoded = utf8.decode(base64Decode(auth.substring(6)));
        final parts = decoded.split(':');
        _usernameCtrl.text = parts[0];
        _passwordCtrl.text = parts.length > 1 ? parts[1] : '';
      } else if (auth.startsWith("Bearer ")) {
        _authType = "Bearer Token";
        _tokenCtrl.text = auth.substring(7);
      }
    } else if (headers.isNotEmpty) {
      _authType = "Custom Header";
      final key = headers.keys.first;
      _customHeaderKeyCtrl.text = key;
      _customHeaderValueCtrl.text = headers[key].toString();
    }

    if (headers.containsKey("Content-Type")) {
      final ct = headers["Content-Type"].toString();
      if (_contentTypeOptions.contains(ct)) {
        _contentType = ct;
        _customContentTypeCtrl.clear();
      } else {
        _contentType = 'Custom';
        _customContentTypeCtrl.text = ct;
      }
    }
  }

  void _openHistory() {
    final currentState = widget.bloc.state;

    if (currentState is! RequestLoaded || currentState.requests.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No history available')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final searchCtrl = TextEditingController();
        List<ApiRequest> filtered = List.from(currentState.requests);

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SizedBox(
                height: 500,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: searchCtrl,
                        decoration: InputDecoration(
                          labelText: 'Search history',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() {
                            filtered = currentState.requests
                                .where((r) =>
                            r.name
                                .toLowerCase()
                                .contains(value.toLowerCase()) ||
                                r.url
                                    .toLowerCase()
                                    .contains(value.toLowerCase()))
                                .toList();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final req = filtered[index];
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              title: Text(req.name),
                              subtitle: Text('${req.method} ${req.url}'),
                              onTap: () {
                                _nameCtrl.text = req.name;
                                _urlCtrl.text = req.url;
                                _bodyCtrl.text = req.body ?? '';
                                _method = req.method;
                                _selectedEnvironmentId = req.environmentId;
                                _loadAuthFromHeaders(req.headers);

                                setState(() {});
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = widget.isPro;

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(12),
          elevation: 0,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: _inputDecoration(
                    'Request Name',
                    suffix: IconButton(
                      icon: const Icon(Icons.history),
                      onPressed: _openHistory,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _method,
                  decoration: _inputDecoration('Method'),
                  items: ['GET', 'POST', 'PUT', 'DELETE']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _method = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlCtrl,
                  decoration: _inputDecoration('URL'),
                ),
                const SizedBox(height: 12),
                // Authentication / Environment
                isPro
                    ? DropdownButtonFormField<int>(
                  value: _selectedEnvironmentId,
                  decoration: _inputDecoration("Environment"),
                  items: [
                    ..._environments
                        .map((c) => DropdownMenuItem(
                      value: c['id'] as int,
                      child: Text(c['name'] as String),
                    ))
                        .toList(),
                    const DropdownMenuItem(
                      value: -1,
                      child: Text("+ Add New Environment",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                    ),
                  ],
                  onChanged: (v) async {
                    if (v == -1) {
                      Navigator.pushNamed(context, "/environments")
                          .then((_) => _loadEnvironments());
                      return;
                    }
                    setState(() => _selectedEnvironmentId = v);
                    if (v != null &&
                        (_nameCtrl.text.isEmpty &&
                            _urlCtrl.text.isEmpty ||
                            _authType == 'None')) {
                      final e = await repo.getById(v);
                      final env = e?.toJson();
                      if (env != null) _loadAuthFromHeaders(env['auth'] as String?);
                      setState(() {});
                    }
                  },
                )
                    : DropdownButtonFormField<String>(
                  value: _authType,
                  decoration: _inputDecoration("Authentication"),
                  items: ["None", "Basic", "Bearer Token", "Custom Header"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _authType = v!),
                ),
                if (_authType == "Basic") ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameCtrl,
                    decoration: _inputDecoration('Username'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordCtrl,
                    decoration: _inputDecoration('Password'),
                    obscureText: true,
                  ),
                ],
                if (_authType == "Bearer Token") ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tokenCtrl,
                    decoration: _inputDecoration('Bearer Token'),
                  ),
                ],
                if (_authType == "Custom Header") ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customHeaderKeyCtrl,
                    decoration: _inputDecoration('Header Key'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customHeaderValueCtrl,
                    decoration: _inputDecoration('Header Value'),
                  ),
                ],
                const SizedBox(height: 16),
                if (isPro)
                  DropdownButtonFormField<String>(
                    value: _contentType,
                    decoration: _inputDecoration("Content-Type"),
                    items: _contentTypeOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _contentType = v!),
                  ),
                if (_contentType == 'Custom') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customContentTypeCtrl,
                    decoration: _inputDecoration(
                        'Custom Content-Type (e.g. application/vnd.api+json)'),
                  ),
                ],
                const SizedBox(height: 16),
                JsonEditorField(controller: _bodyCtrl),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _sendAndSave(isPro),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Send Request'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
