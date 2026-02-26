import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'air_quality_user_friendly_page.dart';


class AirQualityPage extends StatefulWidget {
  const AirQualityPage({super.key});

  @override
  State<AirQualityPage> createState() => _AirQualityPageState();
}

class _AirQualityPageState extends State<AirQualityPage> {

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

  void _add(List<double> list, double value) {
    if (list.length >= maxSamples) list.removeAt(0);
    list.add(value);
  }

  List<FlSpot> _spots(List<double> values) =>
      List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));

  // 🔥 STATUS COLOR
  Color _statusColor(double value, double safe, double danger) {
    if (value > danger) return Colors.red;
    if (value > safe) return Colors.orange;
    return Colors.green;
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                _buildSegmentToggle(context),
                const SizedBox(height: 15),

                Text(
                  "Last Updated: ${lastUpdated!.toLocal().toString().substring(0, 19)}",
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 20),

                // 🔥 LIVE SENSOR BOX ADDED HERE
                _liveSensorBox(),

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

                const SizedBox(height: 15),

                _overallStatusBox(),

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

  // 🔥 LIVE SENSOR BOX UI
  Widget _liveSensorBox() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Text("Live Sensor Readings",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            Wrap(
              spacing: 20,
              runSpacing: 15,
              children: [
                _sensorTile("CO", mq7.isNotEmpty ? mq7.last : 0, "ppm", 9, 30),
                _sensorTile("MQ135", mq135.isNotEmpty ? mq135.last : 0, "ppm", 800, 1500),
                _sensorTile("CO₂", eco2.isNotEmpty ? eco2.last : 0, "ppm", 800, 1200),
                _sensorTile("TVOC", tvoc.isNotEmpty ? tvoc.last : 0, "ppb", 220, 660),
                _sensorTile("Temp", temp.isNotEmpty ? temp.last : 0, "°C", 26, 32),
                _sensorTile("Humidity", hum.isNotEmpty ? hum.last : 0, "%", 60, 75),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _sensorTile(String name, double value, String unit,
      double safe, double danger) {

    final color = _statusColor(value, safe, danger);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name,
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          "${value.toStringAsFixed(1)} $unit",
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color),
        ),
      ],
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
          minY: -0.5,
          maxY: sensors.length.toDouble() - 1 + 0.5,

          borderData: FlBorderData(show: true),

          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 70,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) {
                    return const SizedBox();
                  }

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
            rightTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  .map((e) =>
                      FlSpot(e.key.toDouble(), index.toDouble()))
                  .toList(),
              isCurved: false,
              barWidth: 3,
              color: values.isNotEmpty
                  ? _statusColor(values.last, safe, danger)
                  : Colors.grey,
              dotData: FlDotData(show: false),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ================= OVERALL STATUS BOX =================

Widget _overallStatusBox() {

  final coState = _statusColor(mq7.isNotEmpty ? mq7.last : 0, 9, 30);
  final tempState = _statusColor(temp.isNotEmpty ? temp.last : 0, 26, 32);
  final humState = _statusColor(hum.isNotEmpty ? hum.last : 0, 60, 75);
  final tvocState = _statusColor(tvoc.isNotEmpty ? tvoc.last : 0, 220, 660);
  final co2State = _statusColor(eco2.isNotEmpty ? eco2.last : 0, 800, 1200);
  final mqState = _statusColor(mq135.isNotEmpty ? mq135.last : 0, 800, 1500);

  List<Color> states = [
    coState,
    tempState,
    humState,
    tvocState,
    co2State,
    mqState
  ];

  Color overall = Colors.green;
  String alertSensor = "";

  if (states.contains(Colors.red)) {
    overall = Colors.red;
  } else if (states.contains(Colors.orange)) {
    overall = Colors.orange;
  }

  if (coState == Colors.red) alertSensor = "CO ";
  if (mqState == Colors.red) alertSensor += "MQ135 ";
  if (co2State == Colors.red) alertSensor += "CO₂ ";
  if (tvocState == Colors.red) alertSensor += "TVOC ";
  if (tempState == Colors.red) alertSensor += "Temperature ";
  if (humState == Colors.red) alertSensor += "Humidity ";

  String text =
      overall == Colors.red
          ? "DANGEROUS"
          : overall == Colors.orange
              ? "MODERATE"
              : "SAFE";

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: overall.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: overall, width: 1.5),
    ),
    child: Column(
      children: [
        Text(
          "Overall Cabin Air Quality: $text",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: overall,
          ),
        ),
        if (overall == Colors.red && alertSensor.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              "Alert Sensors: $alertSensor",
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
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

                  titlesData: FlTitlesData(

                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 55, // reduced
                        interval: maxY / 4,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                    ),

                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28, // reduced
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                    ),

                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),

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
                      color: Colors.blue,
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

  Widget _buildSegmentToggle(BuildContext context) {
  return Container(
    height: 45,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(25),
    ),
    child: Row(
      children: [

        // GRAPH BUTTON
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(25),
            ),
            alignment: Alignment.center,
            child: const Text(
              "Graph View",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),

        // USER FRIENDLY BUTTON
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AirQualityUserFriendlyPage(),
                ),
              );
            },
            child: const Center(
              child: Text(
                "User Friendly",
                style: TextStyle(
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}
