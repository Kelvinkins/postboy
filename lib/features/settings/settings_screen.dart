import 'package:flutter/material.dart';
import 'package:postboy/features/settings/themes.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart'; // add confetti package

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isPro = false;
  bool _loading = true;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _checkProStatus();
  }

  Future<void> _checkProStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('app_config')
          .get();

      if (doc.exists && doc.data()?['isPremium'] == true) {
        setState(() {
          _isPro = true;
        });
        _confettiController.play(); // celebrate Pro status
      }
    }
    setState(() => _loading = false);
  }

  void _handleUpgrade(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, "/auth");
    } else if (!_isPro) {
      Navigator.pushNamed(context, "/upgrade");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You are already a Pro user! 🎉")),
      );
    }
  }

  void _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, "/auth", (route) => false);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // if (_isPro)
              //   Card(
              //     color: Colors.amber,
              //     elevation: 4,
              //     shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(16)),
              //     child: Padding(
              //       padding: const EdgeInsets.all(16.0),
              //       child: Row(
              //         children: const [
              //           Icon(Icons.workspace_premium, size: 40),
              //           SizedBox(width: 12),
              //           Expanded(
              //             child: Text(
              //               "🎉 Congratulations! You're a Pro user!",
              //               style: TextStyle(
              //                   fontSize: 18, fontWeight: FontWeight.bold),
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
              // const SizedBox(height: 20),

              // Theme switching
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: const Text('Theme'),
                subtitle: Text(isDark ? "Dark mode" : "Light mode"),
                trailing: Switch(
                  value: isDark,
                  onChanged: themeProvider.toggleTheme,
                ),
              ),

              // const Divider(),
              //
              // // Upgrade section
              // ListTile(
              //   leading: const Icon(Icons.workspace_premium, color: Colors.amber),
              //   title: Text(_isPro ? 'You are Pro' : 'Upgrade to Pro'),
              //   subtitle: const Text('Unlock advanced features'),
              //   enabled: !_isPro,
              //   onTap: () => _handleUpgrade(context),
              // ),

              const Divider(),

              // About
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                subtitle: const Text('Postboy v1.0'),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Postboy',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2025 YourName',
                  );
                },
              ),

              const Divider(),

              // Log out
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Log Out'),
                onTap: () => _handleLogout(context),
              ),
            ],
          ),
          if (_isPro)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.amber,
                  Colors.green,
                  Colors.pink,
                  Colors.blue,
                  Colors.orange
                ],
              ),
            ),
        ],
      ),
    );
  }
}
