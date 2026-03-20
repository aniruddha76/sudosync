import 'package:flutter/material.dart';

class SystemMonitor extends StatelessWidget {
  const SystemMonitor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("System Monitor"),
      ),
      body: const Center(
        child: Text("System Monitor coming soon!"),
      ),
    );
  }
}