import 'package:flutter/material.dart';

class TestScreen1 extends StatelessWidget {
  const TestScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("home page"),
      ),
      body: Center(
        child: const Text(
          "gggg",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
