import 'package:flutter/material.dart';

class AirStatus {
  static Map<String, dynamic> co2Status(int value) {
    if (value <= 800) {
      return {"text": "SAFE", "color": Colors.green};
    } else if (value <= 1200) {
      return {"text": "MODERATE", "color": Colors.orange};
    } else {
      return {"text": "ALERT", "color": Colors.red};
    }
  }

  static Map<String, dynamic> tvocStatus(int value) {
    if (value <= 300) {
      return {"text": "SAFE", "color": Colors.green};
    } else if (value <= 600) {
      return {"text": "MODERATE", "color": Colors.orange};
    } else {
      return {"text": "ALERT", "color": Colors.red};
    }
  }
}
