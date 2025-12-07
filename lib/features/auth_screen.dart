import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool loading = false;

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();

    // 🔥 If user already logged in, skip auth screen
    final user = _auth.currentUser;
    if (user != null) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, "/upgrade");
      });
    }
  }

  Future<void> _handleAuth() async {
    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    setState(() => loading = true);

    try {
      if (isLogin) {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      } else {
        await _auth.createUserWithEmailAndPassword(email: email, password: password);
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/upgrade");

    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Authentication error");
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? "Login" : "Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),

            Center(
              child: Text(
                "Postboy",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _handleAuth,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isLogin ? "Login" : "Create Account"),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(isLogin
                    ? "Don't have an account?"
                    : "Already have an account?"),
                TextButton(
                  onPressed: () {
                    setState(() => isLogin = !isLogin);
                  },
                  child: Text(isLogin ? "Sign up" : "Login"),
                )
              ],
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
