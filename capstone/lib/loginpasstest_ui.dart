import 'package:flutter/material.dart';

class LoginPassTestPage extends StatelessWidget {
  const LoginPassTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("home page"),
      ),
      body: Center(
        child: const Text(
          "good",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}