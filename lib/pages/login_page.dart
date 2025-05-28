import 'package:flutter/material.dart';
import '../utils/translations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  final void Function() onLoginSuccess;
  const LoginPage({required this.onLoginSuccess, Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorText;

  void _login() {
    if (_usernameController.text == "admin" && _passwordController.text == "1234") {
      widget.onLoginSuccess();
    } else {
      setState(() {
        _errorText = getText(context, 'invalid_credentials');
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(getText(context, 'login_title'))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(getText(context, 'login_instruction'), style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: getText(context, 'username')),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: getText(context, 'password'),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            SizedBox(height: 12),
            if (_errorText != null)
              Text(_errorText!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _login,
              child: Text(getText(context, 'login_button')),
            ),
          ],
        ),
      ),
    );
  }
}
