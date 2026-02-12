import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class AccidentMonitoringPage extends StatefulWidget {
  const AccidentMonitoringPage({super.key});

  @override
  State<AccidentMonitoringPage> createState() => _AccidentMonitoringPageState();
}

class _AccidentMonitoringPageState extends State<AccidentMonitoringPage> {

  final DatabaseReference sensorRef =
      FirebaseDatabase.instance.ref("air_quality/current");

  final int maxSamples = 25;

  final List<double> mq7 = [];
  final List<double> mq135 = [];
  final List<double> eco2 = [];
  final List<double> tvoc = [];
  final List<double> temp = [];
  final List<double> hum = [];

  DateTime? lastUpdated;

  bool _dangerDialogVisible = false;

  void _add(List<double> list, double value) {
    if (list.length >= maxSamples) list.removeAt(0);
    list.add(value);
  }

  List<FlSpot> _spots(List<double> values) =>
      List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));

  // ===== STATUS COLOR =====
  Color _statusColor(double value, double safe, double danger) {
    if (value > danger) return Colors.red;
    if (value > safe) return Colors.orange;
    return Colors.green;
  }

  void _checkDanger() {
    bool danger =
        mq7.isNotEmpty && mq7.last > 30 ||
        mq135.isNotEmpty && mq135.last > 1500 ||
        eco2.isNotEmpty && eco2.last > 1200 ||
        tvoc.isNotEmpty && tvoc.last > 660 ||
        temp.isNotEmpty && temp.last > 32 ||
        hum.isNotEmpty && hum.last > 75;

    if (danger && !_dangerDialogVisible) {
      _dangerDialogVisible = true;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.red.shade50,
          title: const Text(
            "⚠ Dangerous Air Quality",
            style: TextStyle(color: Colors.red),
          ),
          content: const Text(
            "One or more sensors have reached dangerous levels.\nPlease ventilate immediately.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _dangerDialogVisible = false;
              },
              child: const Text("ACKNOWLEDGE"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("In-Cabin Air Quality Monitoring"),
        centerTitle: true,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: sensorRef.onValue,
        builder: (context, snapshot) {

          if (!snapshot.hasData ||
              snapshot.data!.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data =
              Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          _add(mq7, (data['mq7'] ?? 0).toDouble());
          _add(mq135, (data['mq135'] ?? 0).toDouble());
          _add(eco2, (data['eco2'] ?? 0).toDouble());
          _add(tvoc, (data['tvoc'] ?? 0).toDouble());
          _add(temp, (data['temperature'] ?? 0).toDouble());
          _add(hum, (data['humidity'] ?? 0).toDouble());

          lastUpdated = DateTime.now();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkDanger();
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                Text(
                  "Last Updated: ${lastUpdated!.toLocal().toString().substring(0, 19)}",
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 30),

                const Center(
                  child: Text(
                    "Overall Sensor Trend",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),

                const SizedBox(height: 20),

                _overallGraph(),

                const SizedBox(height: 50),

                const Center(
                  child: Text(
                    "Individual Sensor Graphs",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),

                const SizedBox(height: 25),

                _sensorChart("Carbon Monoxide (MQ-7)", "ppm", mq7, 9, 30),
                _sensorChart("Air Quality Load (MQ-135)", "ppm", mq135, 800, 1500),
                _sensorChart("eCO₂ (SGP30)", "ppm", eco2, 800, 1200),
                _sensorChart("TVOC (SGP30)", "ppb", tvoc, 220, 660),
                _sensorChart("Temperature", "°C", temp, 26, 32),
                _sensorChart("Humidity", "%", hum, 60, 75),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= OVERALL GRAPH =================

  Widget _overallGraph() {

    final sensors = [
      ("Humidity", hum, 60.0, 75.0),
      ("Temperature", temp, 26.0, 32.0),
      ("TVOC", tvoc, 220.0, 660.0),
      ("CO₂", eco2, 800.0, 1200.0),
      ("MQ135", mq135, 800.0, 1500.0),
      ("CO", mq7, 9.0, 30.0),
    ];

    return SizedBox(
      height: 320,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxSamples.toDouble() - 1,
          minY: 0,
          maxY: sensors.length.toDouble() - 1,

          borderData: FlBorderData(show: true),

          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 70,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < sensors.length) {
                    return Text(
                      sensors[index].$1,
                      style: const TextStyle(fontSize: 12),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 11),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),

          lineBarsData: sensors.asMap().entries.map((entry) {

            final index = entry.key;
            final values = entry.value.$2;
            final safe = entry.value.$3;
            final danger = entry.value.$4;

            return LineChartBarData(
              spots: values
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), index.toDouble()))
                  .toList(),
              isCurved: false,
              barWidth: 3,
              gradient: LinearGradient(
                colors: values
                    .map((v) => _statusColor(v, safe, danger))
                    .toList(),
              ),
              dotData: FlDotData(show: false),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ================= INDIVIDUAL SENSOR GRAPH =================

  Widget _sensorChart(
      String title,
      String unit,
      List<double> values,
      double safeLimit,
      double dangerLimit) {

    if (values.isEmpty) return const SizedBox();

    final maxY =
        [...values, safeLimit, dangerLimit].reduce((a, b) => a > b ? a : b) * 1.15;

    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 35),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),

            const SizedBox(height: 4),

            Text("Unit: $unit",
                style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 15),

            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: maxSamples.toDouble() - 1,
                  minY: 0,
                  maxY: maxY,
                  borderData: FlBorderData(show: true),

                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: safeLimit,
                        color: Colors.green,
                        strokeWidth: 2,
                        dashArray: [6, 4],
                      ),
                      HorizontalLine(
                        y: dangerLimit,
                        color: Colors.red,
                        strokeWidth: 2,
                        dashArray: [6, 4],
                      ),
                    ],
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: _spots(values),
                      isCurved: true,
                      barWidth: 3,
                      gradient: LinearGradient(
                        colors: values
                            .map((v) =>
                                _statusColor(v, safeLimit, dangerLimit))
                            .toList(),
                      ),
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
