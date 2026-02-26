import 'package:flutter/material.dart';
import 'air_quality_page.dart';
import 'air_quality_user_friendly_page.dart';
import 'package:air_quality/pages/accident_monitoring_page.dart';


class ModuleOptionsPage extends StatelessWidget {
  final String moduleName;
  const ModuleOptionsPage({super.key, required this.moduleName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(moduleName),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _optionCard(
              context,
              title: "Detailed Graph View",
              subtitle: "Live charts & analysis",
              icon: Icons.show_chart,
              color: Colors.blue,
              onTap: () {
                // ✅ DIRECT NAVIGATION (NO CONDITIONS)
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AirQualityPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _optionCard(
              context,
              title: "User Friendly View",
              subtitle: "Simple status & values",
              icon: Icons.dashboard_customize,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AirQualityUserFriendlyPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
