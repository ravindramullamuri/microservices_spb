import 'package:flutter/material.dart';
import 'package:heart_thrive/constants/ui_constants.dart';

import 'decimal_formatter.dart';

class MealProgressIndicator extends StatelessWidget {
  final String title;          // Old legend title
  final double percent;        // % value (0..100)
  final String valueLabel;     // Sub-label displaying real intake/missed/bmi (e.g. "23.4 kg")
  final double progressValue;  // Used for calculation
  final Color color;

  // NEW: optional weight change and unit (for BMI/weight card)
  final double? weightChange;
  final double? safeWeight;
  final String weightUnit;
  final int? dayCount;
  final double? actualWeight;

  const MealProgressIndicator({
    super.key,
    required this.title,
    required this.percent,
    required this.valueLabel,
    required this.progressValue,
    required this.color,
    this.weightChange,
    this.weightUnit = 'kg',
    this.safeWeight =0,
    this.dayCount=1,
    this.actualWeight =0,
  });

  @override
  Widget build(BuildContext context) {
    final size = deviceWidth(context) > 750 ? 200.0 : deviceWidth(context) > 390 ? 100.0 :80.0;
    final normalized = (percent / 100).clamp(0.0, 1.0); // Progress from % → circle fill

    // Determine color based on condition (existing logic)
    Color statusColor = Colors.green; // default safe

    if (title.contains("Sodium") && progressValue > 2500) {
      progressValue > (2500 * dayCount! ) ? statusColor = Colors.red: Colors.green;
    } else if (title.contains("Missed") && progressValue >= 1) {
      statusColor = Colors.red;
    } else if (title.contains("Body") && percent > 90) {
      statusColor = Colors.red;
    }

    // weight-change display: only when positive (user requested red up arrow for increase)
    final bool showWeightIncrease = (weightChange ?? 0) > 0;
    final double totalWeight = (safeWeight ?? 0) + (weightChange ?? 0);


    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Grey base ring
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: deviceWidth(context) > 750 ? 12:7,
                valueColor: AlwaysStoppedAnimation(Colors.grey.shade300),
              ),
            ),

            // Colored progress ring
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: normalized,
                strokeWidth: deviceWidth(context) > 750 ? 12:7,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),

            // Percent inside
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${percent.toStringAsFixed(0)}%",
                  style:  TextStyle(
                    fontSize:deviceWidth(context) > 750 ?25: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        Text(
          title,
          style:  TextStyle(
            fontSize: deviceWidth(context) > 750 ? 20 :deviceWidth(context) > 360?13:11,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Value label + optional weightChange arrow + value
        // valueLabel already contains bmi and unit, e.g. "23.4 kg"
        /*if (title.contains("Body") && safeWeight != null && weightChange != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "(${actualWeight?.toStringAsFixed(2)} $weightUnit)",
                style: TextStyle(
                  fontSize: deviceWidth(context) > 360?11:10,
                  fontWeight: FontWeight.w600,
                ),
              )
            ],
          ),*/
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title.contains("Body")?'${actualWeight!.toStringAsFixed(2)} $weightUnit ':formatNumberWithCommas(valueLabel),
              style: TextStyle(
                fontSize: deviceWidth(context) > 750 ? 18 :deviceWidth(context) > 360?11:10,
                fontWeight: FontWeight.w600,
                color: title.contains("Body")?Colors.green:statusColor,
              ),
            ),

            if (showWeightIncrease) ...[
              Text(
                // show with one decimal — adjust as needed
                "${weightChange!.toStringAsFixed(2)} $weightUnit",
                style:  TextStyle(
                  fontSize:deviceWidth(context) > 750 ? 18: deviceWidth(context) > 360?11:10,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              // red up arrow
              const Icon(Icons.arrow_upward, size: 14, color: Colors.red),
            ],
          ],
        ),


      ],
    );
  }
}
