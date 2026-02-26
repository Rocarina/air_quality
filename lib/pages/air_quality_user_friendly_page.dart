import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'air_quality_page.dart';

class AirQualityUserFriendlyPage extends StatefulWidget {
  const AirQualityUserFriendlyPage({Key? key}) : super(key: key);

  @override
  State<AirQualityUserFriendlyPage> createState() =>
      _AirQualityUserFriendlyPageState();
}

class _AirQualityUserFriendlyPageState
    extends State<AirQualityUserFriendlyPage>
    with SingleTickerProviderStateMixin {

  final DatabaseReference _ref =
      FirebaseDatabase.instance.ref("air_quality");

  Map<String, dynamic> sensorData = {};

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  String _previousStatus = "Normal";

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  _glowAnimation = Tween<double>(begin: 4, end: 18).animate(
    CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ),
  );
    _ref.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          sensorData = Map<String, dynamic>.from(data);
        });
      }
    });
  }

  // ================= AQI CLASSIFICATION (UNCHANGED) =================

  Map<String, dynamic> classifyCO(double ppm) {
    if (ppm <= 9) return {"text": "Safe", "color": Colors.green};
    if (ppm <= 25) return {"text": "Moderate", "color": Colors.orange};
    return {"text": "Dangerous", "color": Colors.red};
  }

  Map<String, dynamic> classifyCO2(double ppm) {
    if (ppm <= 800) return {"text": "Safe", "color": Colors.green};
    if (ppm <= 1200) return {"text": "Moderate", "color": Colors.orange};
    return {"text": "Dangerous", "color": Colors.red};
  }

  Map<String, dynamic> classifyTVOC(double ppb) {
    if (ppb <= 200) return {"text": "Safe", "color": Colors.green};
    if (ppb <= 500) return {"text": "Moderate", "color": Colors.orange};
    return {"text": "Dangerous", "color": Colors.red};
  }

  Map<String, dynamic> classifyTemp(double temp) {
    if (temp >= 20 && temp <= 30)
      return {"text": "Comfortable", "color": Colors.green};
    if (temp >= 15 && temp <= 35)
      return {"text": "Moderate", "color": Colors.orange};
    return {"text": "Uncomfortable", "color": Colors.red};
  }

  Map<String, dynamic> classifyHumidity(double hum) {
    if (hum >= 40 && hum <= 60)
      return {"text": "Ideal", "color": Colors.green};
    if (hum >= 30 && hum <= 70)
      return {"text": "Moderate", "color": Colors.orange};
    return {"text": "Poor", "color": Colors.red};
  }

  // ================= INFO DIALOG =================

  void showInfo(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  // ================= BAR CARD =================

  Widget buildBarCard(
      String title,
      String subtitle,
      String value,
      String unitExplanation,
      String infoText,
      Map<String, dynamic> status) {

    Color statusColor = status["color"];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => showInfo(title, infoText),
                child: const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 10,
              color: statusColor.withOpacity(0.2),
              child: Container(
                width: double.infinity,
                color: statusColor,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            "$value  ($unitExplanation)",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            status["text"],
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    double co = (sensorData["co_ppm"] ?? 0).toDouble();
    double co2 = (sensorData["co2_ppm"] ?? 0).toDouble();
    double tvoc = (sensorData["tvoc_ppb"] ?? 0).toDouble();
    double temp = (sensorData["temperature"] ?? 0).toDouble();
    double hum = (sensorData["humidity"] ?? 0).toDouble();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0E2A32),
            Color(0xFF1C3F4A),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
        child: SafeArea(
          child: sensorData.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [

                      const Text(
                        "Air Quality - User Friendly",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Expanded(
                        child: ListView(
                          children: [

                            _buildSegmentToggle(context),
                            const SizedBox(height: 15),
                            
                            _buildOverallSummaryCard(co, co2, tvoc, temp, hum),

                            _buildAlertSection(co, co2, tvoc, temp, hum),

                            const SizedBox(height: 10),

                            const Text(
                              "Individual Sensors",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 15),


                            buildBarCard(
                              "Carbon Gas (MQ7)",
                              "Carbon level in cabin air",
                              "$co ppm",
                              "parts per million",
                              "Measures carbon-based gas concentration inside the vehicle cabin.",
                              classifyCO(co),
                            ),

                            buildBarCard(
                              "Cabin Freshness (MQ135)",
                              "Air freshness level",
                              "$co2 ppm",
                              "parts per million",
                              "Indicates how fresh or stale the cabin air is.",
                              classifyCO2(co2),
                            ),

                            buildBarCard(
                              "Chemical Vapors (SGP30)",
                              "Chemical gases in air",
                              "$tvoc ppb",
                              "parts per billion",
                              "Detects chemical vapors and airborne compounds.",
                              classifyTVOC(tvoc),
                            ),

                            buildBarCard(
                              "Temperature (DHT11)",
                              "Cabin temperature",
                              "$temp °C",
                              "degrees Celsius",
                              "Shows the temperature inside the vehicle cabin.",
                              classifyTemp(temp),
                            ),

                            buildBarCard(
                              "Humidity (DHT11)",
                              "Moisture in air",
                              "$hum %",
                              "percentage humidity",
                              "Shows the amount of moisture present in cabin air.",
                              classifyHumidity(hum),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

  Widget _buildSegmentToggle(BuildContext context) {
  return Container(
    height: 42,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Stack(
      children: [

        // 🔵 Sliding Animated Pill (User selected here)
        AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.centerRight,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
          ),
        ),

        Row(
          children: [

            // GRAPH
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AirQualityPage(),
                    ),
                  );
                },
                child: const Center(
                  child: Text(
                    "Graph View",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),

            // USER FRIENDLY (ACTIVE)
            Expanded(
              child: const Center(
                child: Text(
                  "User Friendly",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

@override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

Widget _buildOverallSummaryCard(
  double co,
  double co2,
  double tvoc,
  double temp,
  double hum,
) {

  final coStatus = classifyCO(co);
  final co2Status = classifyCO2(co2);
  final tvocStatus = classifyTVOC(tvoc);
  final tempStatus = classifyTemp(temp);
  final humStatus = classifyHumidity(hum);

  List<Color> states = [
    coStatus["color"],
    co2Status["color"],
    tvocStatus["color"],
    tempStatus["color"],
    humStatus["color"],
  ];

  Color overallColor = Colors.green;
  String overallText = "Normal";

  if (states.contains(Colors.red)) {
    overallColor = Colors.red;
    overallText = "Poor";
  } else if (states.contains(Colors.orange)) {
    overallColor = Colors.orange;
    overallText = "Moderate";
  }

  return AnimatedContainer(
    duration: const Duration(milliseconds: 400),
    margin: const EdgeInsets.only(bottom: 35),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.96),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "OVERALL CABIN AIR QUALITY",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Colors.black54,
          ),
        ),

        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            Text(
              overallText,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: overallColor,
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: overallColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                overallText.toUpperCase(),
                style: TextStyle(
                  color: overallColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _miniStatus("CO", coStatus),
            _miniStatus("CO₂", co2Status),
            _miniStatus("VOC", tvocStatus),
            _miniStatus("Temp", tempStatus),
            _miniStatus("Humidity", humStatus),
          ],
        ),
      ],
    ),
  );
}

Widget _miniStatus(String label, Map<String, dynamic> status) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: status["color"],
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

Widget _buildAlertSection(
  double co,
  double co2,
  double tvoc,
  double temp,
  double hum,
) {
  List<Map<String, dynamic>> alerts = [];

  // ===== CO (MQ7) =====
  if (co > 9 && co <= 30) {
    alerts.add({
      "title": "Carbon Monoxide Moderate",
      "color": Colors.orange,
      "message": "CO levels are slightly high.",
      "action": "Open windows and improve ventilation."
    });
  } else if (co > 30) {
    alerts.add({
      "title": "Carbon Monoxide DANGER",
      "color": Colors.red,
      "message": "High Carbon Monoxide detected!",
      "action": "Stop vehicle immediately and move to fresh air."
    });
  }

  // ===== CO2 =====
  if (co2 > 800 && co2 <= 1200) {
    alerts.add({
      "title": "CO₂ Moderate",
      "color": Colors.orange,
      "message": "Cabin air becoming stale.",
      "action": "Open windows to improve airflow."
    });
  } else if (co2 > 1200) {
    alerts.add({
      "title": "CO₂ DANGER",
      "color": Colors.red,
      "message": "High CO₂ concentration detected!",
      "action": "Ventilate immediately or step outside."
    });
  }

  // ===== TVOC =====
  if (tvoc > 220 && tvoc <= 660) {
    alerts.add({
      "title": "Chemical Vapors Moderate",
      "color": Colors.orange,
      "message": "VOC levels rising.",
      "action": "Avoid chemical sources and ventilate cabin."
    });
  } else if (tvoc > 660) {
    alerts.add({
      "title": "Chemical Vapors DANGER",
      "color": Colors.red,
      "message": "High toxic vapor levels!",
      "action": "Leave enclosed space immediately."
    });
  }

  // ===== Temperature =====
  if (temp > 26 && temp <= 32) {
    alerts.add({
      "title": "Temperature Moderate",
      "color": Colors.orange,
      "message": "Cabin temperature rising.",
      "action": "Turn on AC or improve airflow."
    });
  } else if (temp > 32) {
    alerts.add({
      "title": "Temperature DANGER",
      "color": Colors.red,
      "message": "Excessive cabin heat!",
      "action": "Stop vehicle and cool environment immediately."
    });
  }

  // ===== Humidity =====
  if (hum > 60 && hum <= 75) {
    alerts.add({
      "title": "Humidity Moderate",
      "color": Colors.orange,
      "message": "Humidity increasing.",
      "action": "Use AC or dehumidifier."
    });
  } else if (hum > 75) {
    alerts.add({
      "title": "Humidity DANGER",
      "color": Colors.red,
      "message": "High moisture levels detected!",
      "action": "Reduce humidity immediately."
    });
  }

  if (alerts.isEmpty) {
    return const SizedBox(); // No alerts if everything safe
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 10),
      const Text(
        "⚠ Alerts & Recommendations",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 15),

      ...alerts.map((alert) {
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: alert["color"].withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: alert["color"]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert["title"],
                style: TextStyle(
                  color: alert["color"],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(alert["message"]),
              const SizedBox(height: 6),
              Text(
                "Action: ${alert["action"]}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }).toList(),
    ],
  );
}

}
