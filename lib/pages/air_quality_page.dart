import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class AirQualityPage extends StatefulWidget {
  const AirQualityPage({super.key});

  @override
  State<AirQualityPage> createState() => _AirQualityPageState();
}

class _AirQualityPageState extends State<AirQualityPage> {
  final DatabaseReference sensorRef =
      FirebaseDatabase.instance.ref("air_quality/current");

  final int maxSamples = 20;

  final List<double> mq7 = [];
  final List<double> mq135 = [];
  final List<double> eco2 = [];
  final List<double> tvoc = [];
  final List<double> temp = [];
  final List<double> hum = [];

  DateTime? lastUpdated;

  // ================= HELPERS =================
  double _clamp(double v, double min, double max) =>
      v.isNaN ? min : v.clamp(min, max);

  void _add(List<double> list, double value) {
    if (list.length >= maxSamples) list.removeAt(0);
    list.add(value);
  }

  List<FlSpot> _spots(List<double> values) =>
      List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));

  String _status(double v, double safe, double danger) {
    if (v > danger) return "DANGEROUS";
    if (v > safe) return "MODERATE";
    return "SAFE";
  }

  Color _sensorColor(String key) {
    switch (key) {
      case "MQ7":
        return Colors.teal;
      case "MQ135":
        return Colors.indigo;
      case "eCO2":
        return Colors.blue;
      case "TVOC":
        return Colors.deepOrange;
      case "TEMP":
        return Colors.purple;
      case "HUM":
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Air Quality Monitoring"),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: sensorRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data =
              Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          _add(mq7, _clamp((data['mq7'] ?? 0).toDouble(), 0, 1200));
          _add(mq135, _clamp((data['mq135'] ?? 0).toDouble(), 0, 1200));
          _add(eco2, _clamp((data['eco2'] ?? 0).toDouble(), 0, 5000));
          _add(tvoc, _clamp((data['tvoc'] ?? 0).toDouble(), 0, 3000));
          _add(temp, _clamp((data['temperature'] ?? 0).toDouble(), -10, 80));
          _add(hum, _clamp((data['humidity'] ?? 0).toDouble(), 0, 100));

          lastUpdated = DateTime.now();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "Last updated: ${lastUpdated!.toLocal().toString().substring(0, 19)}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 24),

                // ================= LIVE SUMMARY (CENTERED) =================
                const _SectionHeader(
                  title: "Live Sensor Summary",
                  subtitle: "Current real-time readings from all sensors",
                ),
                const SizedBox(height: 12),
                Center(child: _summaryBox()),
                const SizedBox(height: 20),

                _legendBar(),
                const SizedBox(height: 36),

                // ================= OVERALL =================
                const _SectionHeader(
                  title: "Overall Sensor Trends",
                  subtitle:
                      "Combined view showing trends of all sensors over time",
                ),
                const SizedBox(height: 16),
                _overallReadableGraph(),

                const SizedBox(height: 40),

                // ================= INDIVIDUAL =================
                const _SectionHeader(
                  title: "Individual Sensor Visualization",
                  subtitle:
                      "Detailed analysis of each sensor with safe & danger limits",
                ),
                const SizedBox(height: 20),

                _chart("MQ-7 Sensor", "MQ7", mq7, 700, 900),
                _chart("MQ-135 Sensor", "MQ135", mq135, 700, 900),
                _chart("eCO₂ Sensor", "eCO2", eco2, 800, 1200),
                _chart("TVOC Sensor", "TVOC", tvoc, 220, 600),
                _chart("Temperature Sensor", "TEMP", temp, 35, 45),
                _chart("Humidity Sensor", "HUM", hum, 60, 80),

                const SizedBox(height: 28),

                // ================= ALERTS =================
                const _SectionHeader(
                  title: "Alerts & Precautions",
                  subtitle:
                      "Warnings and recommended actions based on sensor levels",
                ),
                const SizedBox(height: 12),
                _alertSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= SUMMARY =================
  Widget _summaryBox() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _mini("MQ-7", mq7.last, "ADC"),
                _mini("MQ-135", mq135.last, "ADC"),
                _mini("eCO₂", eco2.last, "ppm"),
                _mini("TVOC", tvoc.last, "ppb"),
                _mini("Temp", temp.last, "°C"),
                _mini("Humidity", hum.last, "%"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(String label, double value, String unit) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value.toStringAsFixed(1),
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(unit, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  // ================= OVERALL NORMALIZED TREND GRAPH (FINAL FIX) =================
Widget _overallReadableGraph() {
  final sensors = [
    ("HUM", hum, "%", 0.0, 100.0),
    ("TEMP", temp, "°C", 0.0, 80.0),
    ("VOC", tvoc, "ppb", 0.0, 600.0),
    ("CO₂", eco2, "ppm", 400.0, 1200.0),
    ("MQ135", mq135, "ADC", 0.0, 900.0),
    ("MQ7", mq7, "ADC", 0.0, 900.0),
  ];

  const double amplitude = 0.25; // controlled vertical wiggle

  LineChartBarData buildLine(
    String key,
    List<double> values,
    int index,
    double min,
    double max,
  ) {
    return LineChartBarData(
      spots: List.generate(values.length, (i) {
        final normalized =
            ((values[i] - min) / (max - min)).clamp(0.0, 1.0);

        // ✅ Line centered exactly on its label row
        final y = index + (normalized - 0.5) * amplitude;

        return FlSpot(i.toDouble(), y);
      }),
      isCurved: true,
      barWidth: 2.5,
      color: _sensorColor(key),
      dotData: FlDotData(show: false),
    );
  }

  return SizedBox(
    height: 320,
    child: LineChart(
      LineChartData(
        minX: 0,
        maxX: maxSamples.toDouble() - 1,
        minY: 0,
        maxY: sensors.length.toDouble(),

        // ================= TOOLTIP (REAL VALUES) =================
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.shade700,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final sensorIndex = spot.barIndex;
                final timeIndex = spot.x.toInt();

                final sensor = sensors[sensorIndex];
                final sensorName = sensor.$1;
                final sensorValues = sensor.$2;
                final unit = sensor.$3;

                // ✅ SAFE INDEX (MATCHES SUMMARY BOX)
                final int safeIndex =
                    timeIndex.clamp(0, sensorValues.length - 1);

                final double realValue = sensorValues[safeIndex];

                return LineTooltipItem(
                  "$sensorName\n${realValue.toStringAsFixed(1)} $unit",
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                );
              }).toList();
            },
          ),
        ),

        // ================= AXES =================
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget:
                const Text("Sensors (Normalized Trend)"),
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 50,
              getTitlesWidget: (v, _) {
                final index = v.toInt();
                if (index >= 0 && index < sensors.length) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      sensors[index].$1,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text("Time (samples)"),
            sideTitles:
                SideTitles(showTitles: true, interval: 5),
          ),
        ),

        // ================= LINES =================
        lineBarsData: List.generate(
          sensors.length,
          (i) => buildLine(
            sensors[i].$1,
            sensors[i].$2,
            i,
            sensors[i].$4,
            sensors[i].$5,
          ),
        ),
      ),
    ),
  );
}

  // ================= INDIVIDUAL GRAPH =================
Widget _chart(
    String title, String key, List<double> values, double safe, double danger) {
  final status = _status(values.last, safe, danger);
  final color = _sensorColor(key);

  // ✅ DYNAMIC RANGE CALCULATION (FIX)
  final double maxValue =
      [...values, safe, danger].reduce((a, b) => a > b ? a : b);

  final double minValue =
      [...values, safe, danger].reduce((a, b) => a < b ? a : b);

  final double rangePadding = (maxValue - minValue) * 0.25;

  return Card(
    elevation: 8,
    margin: const EdgeInsets.only(bottom: 28),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title — $status",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxSamples.toDouble() - 1,

                // ✅ FIXED AXIS RANGE
                minY: (minValue - rangePadding).clamp(0, double.infinity),
                maxY: maxValue + rangePadding,

                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 70,
                      interval:
                          ((maxValue + rangePadding) / 4).ceilToDouble(),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text("Time (samples)"),
                    sideTitles:
                        SideTitles(showTitles: true, interval: 5),
                  ),
                ),

                extraLinesData: ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: safe,
                    color: Colors.green,
                    strokeWidth: 2,
                    dashArray: [6, 4],
                  ),
                  HorizontalLine(
                    y: danger,
                    color: Colors.red,
                    strokeWidth: 2,
                    dashArray: [6, 4],
                  ),
                ]),

                lineBarsData: [
                  LineChartBarData(
                    spots: _spots(values),
                    isCurved: true,
                    barWidth: 3,
                    color: color,
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

  // ================= ALERTS =================
  Widget _alertSection() {
    final List<String> alerts = [];

    void check(String name, double v, double safe, double danger, String tip) {
      if (v > danger) {
        alerts.add("🚨 $name is DANGEROUS — $tip");
      } else if (v > safe) {
        alerts.add("⚠️ $name is MODERATE — To stay safe: $tip");
      }
    }

    check("TEMP", temp.last, 35, 45, "Turn on AC or reduce heat exposure");
    check("HUM", hum.last, 60, 80, "Use ventilation or dehumidifier");
    check("eCO₂", eco2.last, 800, 1200, "Increase cabin ventilation");
    check("TVOC", tvoc.last, 220, 600, "Avoid perfumes and ventilate");

    if (alerts.isEmpty) {
      return const Text("✅ All conditions are safe",
          style:
              TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: alerts
          .map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(a,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600)),
              ))
          .toList(),
    );
  }
}

// ================= SECTION HEADER =================
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const Divider(thickness: 1.2),
      ],
    );
  }
}

// ================= LEGEND =================
Widget _legendBar() {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        _LegendItem(color: Colors.green, text: "SAFE"),
        _LegendItem(color: Colors.orange, text: "MODERATE"),
        _LegendItem(color: Colors.red, text: "DANGEROUS"),
      ],
    ),
  );
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
