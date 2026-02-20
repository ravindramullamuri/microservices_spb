import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/constants/ui_constants.dart';

import '../../components/ui_components.dart';
import '../../models/medication/medication_intake_summary.dart';
import '../../models/medication/medication_schedule_overview.dart';
import '../../providers/medication/medication_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';
import 'medication_dose_banner.dart';

// Medication Show More & Less Info Provider
final showMoreInfoProvider = StateProvider<bool>((ref) => false);

/// ---------------------------------------------------------------------------
/// MEDICATION HOME CARD
/// ---------------------------------------------------------------------------
class MedicationHomeCard extends ConsumerStatefulWidget {
  const MedicationHomeCard({super.key});

  @override
  ConsumerState<MedicationHomeCard> createState() => _MedicationHomeCardState();
}

class _MedicationHomeCardState extends ConsumerState<MedicationHomeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(medicationScheduleOverviewProvider);
    final intakeAsync = ref.watch(intakeMedicationSummaryProvider);
    _expanded = ref.watch(showMoreInfoProvider);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildWrapperInkWell(context,
              (){
                AppRouter.navigateToAllMedication(context, pageType: "home");
              },
              Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                _header(context),
                const SizedBox(height: 8),
                /// SUMMARY
                _summary(scheduleAsync, intakeAsync),
              ],
            ),
          )
          ),

          const SizedBox(height: 10),

          /// ACTION ROW
          Row(
            children: [
              buildLessAndMoreInfoButton(
                context,
                showMoreInfo: _expanded,
                onTap: () {
                  ref.read(showMoreInfoProvider.notifier).state = !_expanded;
                },
              ),
              const Spacer(),
              buildDashboardButton(
                context,
                () => AppRouter.navigateToMedicationDashboard(context),
              ),
            ],
          ),

          /// DETAILS (ONLY WHEN EXPANDED)
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _details(scheduleAsync),
            ),
        ],
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// HEADER
  /// -------------------------------------------------------------------------
  Widget _header(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        headerTitle(context,"Medication"),
        buildAddNewButton(context, () {
          AppRouter.navigateToAllMedication(context, pageType: "home");
        }),
      ],
    );
  }

  /// -------------------------------------------------------------------------
  /// SUMMARY
  /// -------------------------------------------------------------------------
  Widget _summary(
    AsyncValue<MedicationInfoScheduleOverview?> schedule,
    AsyncValue<IntakeMedicationSummary?> intake,
  ) {
    return schedule.when(
      loading: () => const _Loading(),
      error: (e, _) => const SizedBox(),
      data: (scheduleData) {
        if (scheduleData == null) return const SizedBox();
        return intake.when(
          loading: () => const _Loading(),
          error: (e, _) {
            return Row(
              children: [
                _summaryNumber("0", "Doses\nTaken"),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Text(
                        "0 Target",
                        style:  TextStyle(
                          fontSize: deviceWidth(context)> 750? 20:16,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: 0,
                        minHeight: 5,
                        backgroundColor: Colors.grey[300],
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircleAvatar(
                            radius: 4,
                            backgroundColor: Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "0 Missed Doses",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _summaryNumber("0", "Doses\nLeft"),
              ],
            );
          },
          data: (intakeData) => Column(
            children: [
              _summaryContent(intakeData),
              if (intakeData != null)
                MedicationDoseBanner(
                  key: ValueKey(intakeData.hashCode),
                  intakeSummary: intakeData,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryContent(IntakeMedicationSummary? intake) {
    final taken = intake?.data?.totalTaken ?? 0;
    final target = intake?.data?.totalScheduled ?? 0;
    final missed = intake?.data?.totalMissed ?? 0;
    final left = intake?.data?.totalNotTaken ?? 0;

    final progress = target == 0 ? 0.0 : taken / target;

    return Row(
      children: [
        _summaryNumber("$taken", "Doses\nTaken"),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Text(
                "$target Target",
                style:  TextStyle(
                  fontSize: deviceWidth(context)> 750? 20:16,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 5,
                backgroundColor: Colors.grey[300],
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(radius: 4, backgroundColor: Colors.red),
                  const SizedBox(width: 6),
                  Text(
                    "$missed Missed Doses",
                    style:  TextStyle(fontSize: deviceWidth(context)> 750? 18: 13, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
        _summaryNumber("$left", "Doses\nLeft"),
      ],
    );
  }

  Widget _summaryNumber(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style:  TextStyle(fontSize: deviceWidth(context)> 750?18:16, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style:  TextStyle(fontSize: deviceWidth(context)> 750?16:12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// DETAILS
  /// -------------------------------------------------------------------------
  Widget _details(AsyncValue<MedicationInfoScheduleOverview?> async) {
    return async.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (res) {
        if (res == null) return const SizedBox();
        return _buildMedicationDetails(res);
      },
    );
  }

  Widget _buildMedicationDetails(
    MedicationInfoScheduleOverview medicationInfoScheduleOverview,
  ) {
    final data = medicationInfoScheduleOverview.data;

    if (data == null) {
      return const Center(child: Text("No data available"));
    }

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LEFT SIDE — auto height
                  Expanded(
                    child: _medicationListCard(
                      "Today's Medicines",
                      "lib/assets/timer_up_down.png",
                      data.allSchedules,
                      take: 6,
                      forceMinHeight: true,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // RIGHT SIDE — two cards but together matching height
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: _medicationListCard(
                            "Next Doses",
                            "lib/assets/clock_blue.png",
                            data.upcomingSchedules,
                            take: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _medicationListCard(
                            "Missed Doses",
                            "lib/assets/close_icon.png",
                            data.missedSchedules,
                            take: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        data.allSchedules.isNotEmpty ?buildTitleWithIconButton(
          context,
            (){
              AppRouter.navigateToAllMedication(
                context,
                isViewFullMode: true,
              );
            },
          "View Full Info",
          Icons.arrow_forward
        ):SizedBox.shrink()
      ],
    );
  }

  Widget _medicationListCard(
    String title,
    String iconPath,
    List<Schedule> list, {
    int take = 2,
    bool forceMinHeight = false,
  }) {
    final items = list.take(take).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(title, style: deviceWidth(context)>750? AppTheme.title16:AppTheme.title12)),
                Image.asset(
                    iconPath,
                    width: deviceWidth(context)>750?30:24,
                    height: deviceWidth(context)>750?30:24
                ),
              ],
            ),

            const SizedBox(height: 6),

            if (items.isEmpty) const Text("No data", style: AppTheme.body12),

            ...items.map((d) => _medicationItem(d)),

            if (forceMinHeight) const Spacer(),
          ],
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// UI HELPERS
  /// -------------------------------------------------------------------------
  Widget _medicationItem(Schedule d) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            d.formattedTime, // 🔥 use getter inside
            style: deviceWidth(context)> 750? AppTheme.body16:AppTheme.body10,
          ),
          const SizedBox(width: 8),

          Flexible(
            child: Tooltip(
              message: d.medicationName,
              child: Text(
                d.medicationName,
                style: deviceWidth(context)> 750? AppTheme.body14:AppTheme.body10,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

/// ---------------------------------------------------------------------------
/// COMMON
/// ---------------------------------------------------------------------------
BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: const [
      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
    ],
  );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _Error extends StatelessWidget {
  final String message;
  const _Error(this.message);

  @override
  Widget build(BuildContext context) =>
      Text(message, style: const TextStyle(color: Colors.red));
}
