import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class AccidentMonitoringPage extends StatefulWidget {
  const AccidentMonitoringPage({super.key});

  @override
  State<AccidentMonitoringPage> createState() =>
      _AccidentMonitoringPageState();
}

class _AccidentMonitoringPageState
    extends State<AccidentMonitoringPage> {

  final DatabaseReference accidentRef =
      FirebaseDatabase.instance.ref("accident_detection/current");

  final int maxSamples = 20;

  final List<double> xAxis = [];
  final List<double> yAxis = [];
  final List<double> zAxis = [];
  final List<double> shock = [];

  DateTime? lastUpdated;

  // ---------------- HELPERS ----------------

  void _add(List<double> list, double value) {
    if (list.length >= maxSamples) list.removeAt(0);
    list.add(value);
  }

  List<FlSpot> _spots(List<double> values) =>
      List.generate(values.length,
          (i) => FlSpot(i.toDouble(), values[i]));

  String _status(double shockValue) {
    if (shockValue > 800) return "ACCIDENT DETECTED";
    if (shockValue > 500) return "IMPACT WARNING";
    return "SAFE";
  }

  Color _statusColor(String status) {
    switch (status) {
      case "ACCIDENT DETECTED":
        return Colors.red;
      case "IMPACT WARNING":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Accident Monitoring"),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: accidentRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.data!.snapshot.value == null) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final data = Map<String, dynamic>.from(
              snapshot.data!.snapshot.value as Map);

          _add(xAxis, (data['x'] ?? 0).toDouble());
          _add(yAxis, (data['y'] ?? 0).toDouble());
          _add(zAxis, (data['z'] ?? 0).toDouble());
          _add(shock, (data['shock'] ?? 0).toDouble());

          lastUpdated = DateTime.now();

          final status = _status(shock.last);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                Text(
                  "Last updated: ${lastUpdated.toString().substring(0,19)}",
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey),
                ),

                const SizedBox(height: 20),

                // ---------- LIVE SUMMARY ----------
                _summaryBox(status),

                const SizedBox(height: 30),

                // ---------- OVERALL GRAPH ----------
                const Text(
                  "Acceleration & Shock Trends",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _overallGraph(),

                const SizedBox(height: 30),

                // ---------- INDIVIDUAL ----------
                _individualChart("X Axis", xAxis, 5, 10),
                _individualChart("Y Axis", yAxis, 5, 10),
                _individualChart("Z Axis", zAxis, 5, 10),
                _individualChart("Shock Sensor", shock, 500, 800),

                const SizedBox(height: 20),

                _alertSection(status),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------- SUMMARY ----------------

  Widget _summaryBox(String status) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _mini("X", xAxis.last),
                _mini("Y", yAxis.last),
                _mini("Z", zAxis.last),
                _mini("Shock", shock.last),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              status,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _statusColor(status),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(String label, double value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600)),
        Text(value.toStringAsFixed(2),
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ---------------- OVERALL GRAPH ----------------

  Widget _overallGraph() {
    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
                spots: _spots(xAxis),
                color: Colors.blue,
                isCurved: true),
            LineChartBarData(
                spots: _spots(yAxis),
                color: Colors.green,
                isCurved: true),
            LineChartBarData(
                spots: _spots(zAxis),
                color: Colors.orange,
                isCurved: true),
            LineChartBarData(
                spots: _spots(shock),
                color: Colors.red,
                isCurved: true),
          ],
        ),
      ),
    );
  }

  // ---------------- INDIVIDUAL ----------------

  Widget _individualChart(
      String title,
      List<double> values,
      double safe,
      double danger) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  extraLinesData:
                      ExtraLinesData(horizontalLines: [
                    HorizontalLine(
                        y: safe,
                        color: Colors.green),
                    HorizontalLine(
                        y: danger,
                        color: Colors.red),
                  ]),
                  lineBarsData: [
                    LineChartBarData(
                        spots: _spots(values),
                        isCurved: true,
                        color: Colors.purple),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- ALERT ----------------

  Widget _alertSection(String status) {
    if (status == "SAFE") {
      return const Text(
        "✅ No accident detected",
        style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold),
      );
    }

    return Text(
      "🚨 Emergency! Accident detected. Immediate action required.",
      style: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 16),
    );
  }
}

