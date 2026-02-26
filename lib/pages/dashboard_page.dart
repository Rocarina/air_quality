import 'package:flutter/material.dart';
import 'air_quality_page.dart';
import 'air_quality_user_friendly_page.dart';
import 'package:air_quality/pages/accident_monitoring_page.dart';


class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  void _showOptions(BuildContext context, String module) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              module,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.show_chart, color: Colors.blue),
              title: const Text("Detailed Graph View"),
              subtitle: const Text("Live charts & analysis"),
              onTap: () {
                Navigator.pop(context);

                if (module == "Air Quality") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AirQualityPage(),
                    ),
                  );
                } 
                else if (module == "Accident Detection") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccidentMonitoringPage(),
                    ),
                  );
                } 
                else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Module coming soon 🚧"),
                    ),
                  );
                }
              },
            ),

            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.green),
              title: const Text("User Friendly View"),
              subtitle: const Text("Simple status & values"),
              onTap: () {
                Navigator.pop(context);

                if (module == "Air Quality") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AirQualityUserFriendlyPage(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("User Friendly View coming soon 🚧"),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      );
    },
  );
}


  Widget _moduleCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return InkWell(
      onTap: () => _showOptions(context, title),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(icon, size: 34, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // 🎯 Responsive aspect ratio
    final double aspectRatio =
        width < 600 ? 1.0 : width < 1000 ? 1.4 : 1.6;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("DriveIQ Dashboard"),
        backgroundColor: Colors.green,
      ),

      // ✅ SCROLL ENABLED HERE
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GridView(
          shrinkWrap: true, // ⭐ IMPORTANT
          physics: const NeverScrollableScrollPhysics(), // ⭐ IMPORTANT
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: aspectRatio,
          ),
          children: [
            _moduleCard(
              context: context,
              title: "Air Quality",
              icon: Icons.air,
              gradient: [Colors.green, Colors.teal],
            ),
            _moduleCard(
              context: context,
              title: "Vehicle Emission",
              icon: Icons.local_shipping,
              gradient: [Colors.blue, Colors.indigo],
            ),
            _moduleCard(
              context: context,
              title: "Parking System",
              icon: Icons.local_parking,
              gradient: [Colors.orange, Colors.deepOrange],
            ),
            _moduleCard(
              context: context,
              title: "Accident Detection",
              icon: Icons.car_crash,
              gradient: [Colors.red, Colors.deepPurple],
            ),
          ],
        ),
      ),
    );
  }
}
