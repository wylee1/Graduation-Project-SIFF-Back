import 'package:flutter/material.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("home page"),
      ),
      body: Center(
        child: const Text(
          "good123123",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
