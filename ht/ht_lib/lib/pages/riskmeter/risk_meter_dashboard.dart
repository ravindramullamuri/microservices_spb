import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/constants/heart_thrive_strings_constants.dart';

import '../../components/animated_section.dart';
import '../../components/heart_risk_meter.dart';
import '../../components/ui_components.dart';
import '../../constants/ui_constants.dart';
import '../../routes/app_router.dart';
import '../../services/home/risk_meter_service.dart';
import '../../theme/app_theme.dart';

class RiskDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final riskAsync = ref.watch(riskMetricsFutureProvider);

    return riskAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) {
        final score = 0.0;
        return AnimatedSection(
          delay: 100,
          child: _buildRiskCard(score, context),
        );
      },
      data: (riskData) {
        debugPrint("riskData 21 ${jsonEncode(riskData)}");
        final score = (riskData.riskSymptom?.score ?? 0).toDouble();
        return AnimatedSection(
          delay: 100,
          child: _buildRiskCard(score, context),
        );
      },
    );
  }
  Widget _buildRiskCard(double score, BuildContext context) {
    debugPrint("deviceWidth @@@ ${deviceWidth(context)}");
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            _getMessageFrameImage(score),
            //height: 80,
            width: MediaQuery.of(context).size.width * 0.95,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's ${HeartThriveStrings.riskTitle} Metrics",
                style: deviceWidth(context) > 750? AppTheme.title20:deviceWidth(context) > 360? AppTheme.title16:AppTheme.title14,
              ),
              buildDashboardButton(context,() {
                AppRouter.navigateToHeartRiskDashboard(context, score);
              }),
            ],
          ),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  //color: Colors.red,
                  //height: 160,
                  width: deviceWidth(context) > 750? 500:200,
                  child: CustomRiskMeter(value: score),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                  child: _buildRiskLegend(context,score)
              ),
            ],
          ),
        ],
      ),
    );
  }
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(.15),
          spreadRadius: 1,
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
  String _getMessageFrameImage(double score) {
    if (score <= 2) {
      return 'lib/assets/risk_meter/very-low-risk.png'; // Green
    } else if (score <= 4) {
      return 'lib/assets/risk_meter/low-risk.png'; // Light Green
    } else if (score <= 6) {
      return 'lib/assets/risk_meter/moderate-risk.png'; // Amber
    } else if (score <= 8) {
      return 'lib/assets/risk_meter/high-risk.png'; // Orange
    } else {
      return 'lib/assets/risk_meter/critical-risk.png'; // Red
    }
  }

  Widget _buildRiskLegend(context,double score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,  // ← Change this line
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildRiskIndicator(context, '0-2 (Very Low)', Colors.green,
            score >= 0 && score <= 2),
        const SizedBox(height: 8),
        _buildRiskIndicator(context, '2-4 (Low)', Colors.lightGreen,
            score > 2 && score <= 4),
        const SizedBox(height: 8),
        _buildRiskIndicator(
            context, '4-6 (Moderate)', Colors.amber, score > 4 && score <= 6),
        const SizedBox(height: 8),
        _buildRiskIndicator(
            context, '6-8 (High)', Colors.orange, score > 6 && score <= 8),
        const SizedBox(height: 8),
        _buildRiskIndicator(
            context, '> 8 (Critical)', Colors.red, score > 8),
      ],
    );
  }
  Widget _buildRiskIndicator(
      BuildContext context,
      String text,
      Color color,
      bool active,
      ) {
    return Padding(
      padding:  EdgeInsets.all(deviceWidth(context)>750?8.0:2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,  // ← Change this line
        children: [
          Container(
            width: deviceWidth(context) > 750? 20:deviceWidth(context) > 360? 12:10,
            height:  deviceWidth(context) > 750? 20: deviceWidth(context) > 360? 12:10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: active
                  ? Border.all(color: Colors.black, width: 2)
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: deviceWidth(context) > 750? 18:deviceWidth(context) > 390 ? 14: deviceWidth(context) > 360 ? 12 :10,
              fontWeight:
              active ? FontWeight.bold : FontWeight.normal,
              color: active ? Colors.black87 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}