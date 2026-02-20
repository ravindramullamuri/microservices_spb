
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:heart_thrive/services/medication_services.dart';
import 'package:heart_thrive/utils/secure_storage_utils.dart';

import '../../models/medication/medication_intake_summary.dart';
import '../../models/medication/medication_schedule_overview.dart';
import '../../utils/date_utils.dart';
import '../token_provider.dart';

final medicationScheduleOverviewProvider =
FutureProvider.autoDispose<MedicationInfoScheduleOverview?>((ref) async {
  //final token = ref.watch(tokenProvider);
  final token = await SecureStorageUtils().read(StorageKeys.accessToken);

  if (token == null || token.isEmpty) {
    throw Exception('Token not available');
  }
  final from = DateFormatUtil.getStartOfDay(DateTime.now());
  final to = DateFormatUtil.getEndOfDay(DateTime.now());
  final tz = await FlutterTimezone.getLocalTimezone();
  return MedicationService().fetchMedicationInfoSummary(
    token,
      from,
      to,
      tz.identifier
  );
});

final intakeMedicationSummaryProvider =
FutureProvider.autoDispose<IntakeMedicationSummary?>((ref) async {
  // 1️⃣ Read token
  //final token = ref.watch(tokenProvider);
  final token = await SecureStorageUtils().read(StorageKeys.accessToken);
  if (token == null || token.isEmpty) {
    throw Exception('Auth token not available');
  }

  // 2️⃣ Compute dates once
  final now = DateTime.now();
  final from = DateFormatUtil.getStartOfDay(now);
  final to = DateFormatUtil.getEndOfDay(now);

  // 3️⃣ Get timezone (async)
  final timezone = await FlutterTimezone.getLocalTimezone();

  // 4️⃣ Call service
  return MedicationService().fetchIntakeCountSummary(
    token,
    from,
    to,
    timezone.identifier, // already a String
  );
});
