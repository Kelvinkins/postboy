import 'package:flutter/material.dart';
import 'package:postboy/core/models/environment.dart';
import 'package:postboy/data/request_repository.dart';

class EnvironmentsScreen extends StatefulWidget {
  const EnvironmentsScreen({super.key});

  @override
  State<EnvironmentsScreen> createState() => _EnvironmentsScreenState();
}

class _EnvironmentsScreenState extends State<EnvironmentsScreen> {
  List<Environment> environments = [];
  bool loading = true;
  final GenericRepository<Environment> repo =
  GenericRepository(tableName: "environments", fromJson: (json) => Environment.fromJson(json));

  @override
  void initState() {
    super.initState();
    _loadEnvironments();
  }

  Future<void> _loadEnvironments() async {
    setState(() => loading = true);
    environments = await repo.getAll();
    setState(() => loading = false);
  }

  Future<void> _showEnvironmentDialog({Environment? env}) async {
    final nameController = TextEditingController(text: env?.name ?? "");
    String selectedAuth = env?.authType ?? "none";
    String? username = env?.username;
    String? password = env?.password;
    String? token = env?.token;
    String? customKey = env?.customHeaderKey;
    String? customValue = env?.customHeaderValue;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(env == null ? "Add Environment" : "Update Environment"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Environment Name"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedAuth,
                  decoration: const InputDecoration(labelText: "Auth Type"),
                  items: ["none", "basic", "bearer", "custom"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedAuth = val ?? "none"),
                ),
                if (selectedAuth == "basic") ...[
                  TextField(
                    decoration: const InputDecoration(labelText: "Username"),
                    onChanged: (val) => username = val,
                    controller: TextEditingController(text: username),
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: "Password"),
                    onChanged: (val) => password = val,
                    controller: TextEditingController(text: password),
                  ),
                ],
                if (selectedAuth == "bearer")
                  TextField(
                    decoration: const InputDecoration(labelText: "Token"),
                    onChanged: (val) => token = val,
                    controller: TextEditingController(text: token),
                  ),
                if (selectedAuth == "custom") ...[
                  TextField(
                    decoration: const InputDecoration(labelText: "Header Key"),
                    onChanged: (val) => customKey = val,
                    controller: TextEditingController(text: customKey),
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: "Header Value"),
                    onChanged: (val) => customValue = val,
                    controller: TextEditingController(text: customValue),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(env == null ? "Add" : "Update")),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final newEnv = Environment(
        id: env?.id,
        name: nameController.text.trim(),
        authType: selectedAuth,
        username: username,
        password: password,
        token: token,
        customHeaderKey: customKey,
        customHeaderValue: customValue,
      );

      if (env == null) {
        await repo.insert(newEnv.toJson());
      } else {
        await repo.update(newEnv.id!, newEnv.toJson());
      }

      _loadEnvironments();
    }
  }

  Future<void> _deleteEnvironment(int id) async {
    await repo.delete(id);
    _loadEnvironments();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final isPro = args?['isPro'] ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Environments"),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showEnvironmentDialog()),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : environments.isEmpty
          ? const Center(child: Text("No environments added yet"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: environments.length,
        itemBuilder: (_, i) {
          final env = environments[i];
          return Dismissible(
            key: ValueKey(env.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              return await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Delete Environment?"),
                  content: Text("Delete '${env.name}'?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
                  ],
                ),
              );
            },
            onDismissed: (_) => _deleteEnvironment(env.id!),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(env.name),
                subtitle: Text(env.authType),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEnvironmentDialog(env: env),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
