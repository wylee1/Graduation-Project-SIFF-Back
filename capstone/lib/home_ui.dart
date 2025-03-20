import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

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
