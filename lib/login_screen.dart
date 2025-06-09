import 'package:flutter/material.dart';
import 'user_session.dart';
import 'user_database.dart';
import 'home_page.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _error = '';
  bool _loading = false;

  void _login() async {
  setState(() {
    _error = '';
    _loading = true;
  });

  String email = _emailController.text.trim();
  String password = _passwordController.text.trim();

  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$');
  if (!emailRegex.hasMatch(email)) {
    setState(() {
      _error = 'Enter a valid email address';
      _loading = false;
    });
    return;
  }

  final db = UserDatabase();
  final user = await db.authenticate(email, password);

  if (user != null) {
    UserSession.username = user['name'];
    UserSession.role = 'patient';

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(userProfile: {
          'name': user['name'],
          'phone': user['phone'],
          'email': user['email'],
          'age': '',
          'gender': '',
          'address': '',
        }),
      ),
    );
  } else {
    setState(() {
      _error = 'Invalid email or password';
      _loading = false;
    });
  }
}

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Login'),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/register');
              },
              child: const Text("Don't have an account? Register here"),
            ),
          ],
        ),
      ),
    );
  }
}
