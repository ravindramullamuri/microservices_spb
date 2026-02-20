import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:heart_thrive/constants/heart_thrive_strings_constants.dart';
import 'package:heart_thrive/constants/ui_constants.dart';

class CustomRiskMeter extends StatelessWidget {
  final double value; // 1–10 risk score

  const CustomRiskMeter({Key? key, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Base meter image
              Image.asset(
                'lib/assets/Meter_Base.png',
                height: deviceWidth(context)>750?250:120,
                fit: BoxFit.contain,
                //width: deviceWidth(context)*0.5,
              ),

              // Rotating arrow
              Positioned(
                bottom: deviceWidth(context)>750?40:10,
                child: Transform.rotate(
                  angle: getNeedleAngle(value),
                  alignment: Alignment.center, // rotate around the bottom center
                  child: Image.asset(
                    'lib/assets/Pin.png',
                    height: deviceWidth(context)>750?50:30, // Adjust size as needed
                    fit: BoxFit.contain,
                  ),
                ),
              ),

            ],
          ),
        ),

         Text(
          HeartThriveStrings.riskMeterTitle,
          style: TextStyle(fontSize: deviceWidth(context)>750 ? 20: 13, color: Colors.black54),
          textAlign: TextAlign.center,
        ),

        Text(
          getRiskLabel(value),
          style: TextStyle(
            fontSize: deviceWidth(context)>750 ? 20:13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  double getNeedleAngle(double value) {
    // Clamp value between 0 and 10
    value = value.clamp(0, 10);

    // Start angle: 180° (left), End angle: 0° (right)
    const double startAngle = math.pi;  // 180°
    const double endAngle = 0;          // 0°

    // Invert the normalized value so needle moves clockwise
    double t = 1 - (value / 10);

    // Interpolate angle
    return startAngle + (endAngle - startAngle) * t;
  }




  String getRiskLabel(double value) {
    if (value <= 2) return "Very Low";
    if (value <= 4) return "Low";
    if (value <= 6) return "Moderate";
    if (value <= 8) return "High";
    return "Critical";
  }
}
