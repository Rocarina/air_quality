import 'package:flutter/material.dart';

class AccidentMonitoringPage extends StatelessWidget {
  const AccidentMonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Accident Monitoring"),
      ),
      body: const Center(
        child: Text(
          "Accident Monitoring System Page",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}