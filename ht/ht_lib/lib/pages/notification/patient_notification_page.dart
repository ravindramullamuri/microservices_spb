import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/providers/bmi/bmi_provider.dart';
import 'package:heart_thrive/providers/user/user_details_provider.dart';
import '../../components/connection_unavailable.dart';
import '../../components/profile_avatar.dart';
import '../../constants/heart_thrive_strings_constants.dart';
import '../../models/notification/notification_model.dart';
import '../../providers/bmi/notification_provider.dart';
import '../../providers/internet_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_utils.dart';

class PatientNotificationPage extends ConsumerStatefulWidget {
  const PatientNotificationPage({super.key});

  @override
  ConsumerState<PatientNotificationPage> createState() =>
      _PatientNotificationPageState();
}

class _PatientNotificationPageState
    extends ConsumerState<PatientNotificationPage> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();
  bool _isMarkingSeen = false;
  @override
  void initState() {
    super.initState();
    debugPrint("Called initState notification Page");

    Future.microtask(() {
      ref.read(notificationProvider.notifier).loadFirstPageNew();
    });

    _search.addListener(() {
      ref.read(notificationProvider.notifier).updateSearch(_search.text);
    });

    _scroll.addListener(() {
      if (_scroll.position.pixels >=
          _scroll.position.maxScrollExtent - 200) {
        ref.read(notificationProvider.notifier).loadNextPage();
      }
    });
  }
  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _search.clear();
    });

    _search.addListener(() {
      ref.read(notificationProvider.notifier).updateSearch(_search.text);
    });

    _scroll.addListener(() {
      if (_scroll.position.pixels >=
          _scroll.position.maxScrollExtent - 200) {
        ref.read(notificationProvider.notifier).loadNextPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider); // THIS re-renders correctly
    final items = ref.watch(notificationProvider.notifier).filteredNotifications;
    final userDetailsAsync = ref.watch(userDetailsDataProvider);
    final user = userDetailsAsync.asData?.value;
    final isOnline = ref.read(isOnlineProvider);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24), // 👈 Adjust the roundness
          ),
        ),
       /* leading: Padding(
          padding: const EdgeInsets.only(left: 15,top: 8,bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6), // round shape
            child: user?.profileImage == null
                ? Image.asset(
              'lib/assets/default_profile_img.png',
              fit: BoxFit.cover,
              gaplessPlayback: true,
              width: 40,
              height: 40,
            )
                : Image.memory(
              base64Decode(user!.profileImage!),
              gaplessPlayback: true,
              fit: BoxFit.cover,
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.account_circle, color: Colors.white),
            ),
          ),
        ),*/
        leading: userProfileAvatar(context:context, user: user,isNavigate: true),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            offset: const Offset(0, 50),
            onSelected: (String value) async {
              setState(() => _isMarkingSeen = true);

              try {
                final unseenUuids = state.notifications
                    .where((n) => n.seen == false)
                    .map((n) => n.uuid)
                    .toList();

                if (unseenUuids.isNotEmpty) {
                  await ref
                      .read(notificationProvider.notifier)
                      .markAllNotificationAsSeen(unseenUuids);
                }
              } finally {
                if (mounted) {
                  setState(() => _isMarkingSeen = false);
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'Mark all notifications as seen',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.checklist,color: Colors.black,),
                    const SizedBox(width: 8),
                    const Text('Mark all notifications as seen'),

                    // Image.asset('',height: 20,width: 20,),

                  ],
                ),
              ),
            ],
          )
        ],
        title: const Center(
          child:  Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => _refresh(),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: Colors.black26,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      Expanded(
                        child: state.isLoading && items.isEmpty
                            ?!isOnline?ConnectionUnavailable(
                          title: HeartThriveStrings.offlineTitle,
                          description:HeartThriveStrings.offlineMessage,
                          buttonText: "Retry",
                          onRetry: () {
                            ref.invalidate(notificationProvider);
                          },
                        ): const Center(child: CircularProgressIndicator())
                            : items.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(8),
                          itemCount: items.length + 1,
                          itemBuilder: (context, index) {
                            if (index == items.length) {
                              return state.isLoading
                                  ? const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Center(
                                    child: CircularProgressIndicator()),
                              )
                                  : const SizedBox();
                            }
                            return _buildCard(items[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 🔥 MARK-AS-SEEN LOADER OVERLAY
          if (_isMarkingSeen)
            Positioned.fill(
              child: Stack(
                children: [
                  const ModalBarrier(
                    dismissible: false,
                    color: Colors.black26, // blur-like effect
                  ),
                  Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Image.asset(
            "lib/assets/back_button.png",
            height: deviceWidth(context) > 750 ? 50 : 35,
            width: deviceWidth(context) > 750 ? 50 : 35,
          ),
        ),

        const SizedBox(width: 2),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: AppTheme.body16.copyWith(fontSize: deviceWidth(context) > 750 ? 24 :16),
              decoration: InputDecoration(
                hintText: 'Search Notifications',
                helperStyle: AppTheme.body16.copyWith(fontSize: deviceWidth(context) > 750 ? 24 :16),
                prefixIcon:  Icon(Icons.search, color: Colors.grey,size: deviceWidth(context) > 750 ? 35 :24,),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding:  EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: deviceWidth(context) > 750 ? 18 :12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(NotificationItem n) {
    debugPrint('Date @@ ${n.createdAt.toString()}');

    final timeZone = ref.read(timeZoneProvider);
    String timeZoneBasedDate = DateFormatUtil().convertUtcToIst(n.createdAt.toString(),timeZone!);
    return GestureDetector(
      onTap: () {
        if (!n.seen) {
          ref
              .read(notificationProvider.notifier)
              .markNotificationAsSeen(n.uuid);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: n.seen
              ? Colors.white
              : AppTheme.primaryColor.withValues(alpha: 0.08),

          borderRadius: BorderRadius.circular(12),

          // 👇 THIS is the missing part
          border: Border.all(
            color: n.seen
                ? Colors.grey.withValues(alpha: 0.25)
                : AppTheme.primaryColor.withValues(alpha: 0.3),
            width: 0.5,
          ),

          boxShadow: n.seen
              ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 0),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
          ]
              : [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Icon(Icons.notifications, color: AppTheme.primaryColor),
            Padding(
              padding:  EdgeInsets.all(deviceWidth(context) > 750 ? 16 :8.0),
              child: Image.asset(detectType(n.title),height:deviceWidth(context) > 750 ? 80 :  50,),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatTitleForDisplay(n.title),
                    style: AppTheme.title14.copyWith(
                    fontSize:deviceWidth(context) > 750 ? 24 :deviceWidth(context) > 360? 14:12
                    ),
                  ),
                  const SizedBox(height: 4),
                  CustomReadMoreText(
                    n.message,
                    maxLines: 3,
                    textAlign: TextAlign.start,
                    style: AppTheme.body14.copyWith(
                      fontSize:deviceWidth(context) > 750 ? 24:deviceWidth(context) > 360 ? 14 : 12,
                    ),
                    showMoreText: ' Show more',
                    showLessText: ' Show less',
                    linkStyle: AppTheme.title14.copyWith(
                      color: AppTheme.primaryColor,
                      fontSize:deviceWidth(context) > 750 ? 24:deviceWidth(context) > 360 ? 14 : 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeZoneBasedDate,
                    style: AppTheme.body14.copyWith(
                        fontSize:deviceWidth(context) > 750? 20:deviceWidth(context) > 360? 12:10
                    ),
                  )
                ],
              ),
            ),
            if (!n.seen)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return noNotificationInformation();
  }
  // No notification
  Widget noNotificationInformation(){
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/assets/no_notification.png',
                  height: deviceWidth(context) > 750?140:100,),
                const SizedBox(height: 10),
                Text(
                  HeartThriveStrings.noNotificationTitle,
                  textAlign: TextAlign.center,
                  style: AppTheme.title16.copyWith(
                      fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  HeartThriveStrings.noNotificationDescription,
                  textAlign: TextAlign.center,
                  style: AppTheme.body14,
                ),
              ],
            ),
          ),
        ),
      ),
    );

  }
  // Detect Type
  String detectType(String title) {
    title = title.toLowerCase();

    if (title.contains("med")) return "assets/notification_icons/medication_reminder.png";
    if (title.contains("sodium")) return "assets/notification_icons/sodium_alert.png";
    if (title.contains("weight")) return "assets/notification_icons/bmi_update.png";

    return "assets/notification_icons/bell.png";
  }

  // IN_APP
  String formatTitleForDisplay(String title) {
    if (title == null) return '';
    var s = title.trim();

    if (s.isEmpty) return '';

    // normalize underscores to hyphens and collapse spaces
    s = s.replaceAll('_', '-').replaceAll(RegExp(r'\s+'), ' ').trim();

    // pattern that finds an IN_APP/IN-APP marker at the end (case-insensitive)
    final endTag = RegExp(r'(?:(?:-|\()?\s*(IN[_-]?APP)\s*(?:\))?)$', caseSensitive: false);

    if (endTag.hasMatch(s)) {
      // remove the marker from the end
      final cleaned = s.replaceFirst(endTag, '').replaceAll(RegExp(r'[-:\s]+$'), '').trim();
      return cleaned;
    }

    // if marker is at the start like "IN_APP High Sodium" or "IN-APP: High Sodium"
    final startTag = RegExp(r'^\s*(IN[_-]?APP)[:\-\s]*', caseSensitive: false);
    if (startTag.hasMatch(s)) {
      final withoutPrefix = s.replaceFirst(startTag, '').trim();
      return withoutPrefix.isEmpty ? '' : withoutPrefix;
    }

    // no marker present -> return normalized title
    return s;
  }


}



class CustomReadMoreText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle style;
  final TextAlign textAlign;
  final String showMoreText;
  final String showLessText;
  final TextStyle linkStyle;

  const CustomReadMoreText(
      this.text, {
        Key? key,
        this.maxLines = 3,
        required this.style,
        this.textAlign = TextAlign.start,
        this.showMoreText = '... show more',
        this.showLessText = ' show less',
        this.linkStyle = const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      }) : super(key: key);

  @override
  State<CustomReadMoreText> createState() => _CustomReadMoreTextState();
}

class _CustomReadMoreTextState extends State<CustomReadMoreText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle =
    DefaultTextStyle.of(context).style.merge(widget.style);

    if (_isExpanded) {
      return RichText(
        textAlign: widget.textAlign,
        text: TextSpan(
          style: effectiveStyle,
          text: widget.text,
          children: [
            TextSpan(
              text: widget.showLessText,
              style: widget.linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => setState(() => _isExpanded = false),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: effectiveStyle),
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        // No overflow → normal text
        if (!textPainter.didExceedMaxLines) {
          return Text(
            widget.text,
            style: effectiveStyle,
            textAlign: widget.textAlign,
          );
        }

        String truncatedText = widget.text;
        int endIndex = truncatedText.length;

        // Iteratively reduce text until it fits with "show more"
        while (endIndex > 0) {
          final testText = truncatedText.substring(0, endIndex) +
              widget.showMoreText;

          final testPainter = TextPainter(
            text: TextSpan(
              text: testText,
              style: effectiveStyle,
              children: [
                TextSpan(text: widget.showMoreText, style: widget.linkStyle),
              ],
            ),
            maxLines: widget.maxLines,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: constraints.maxWidth);

          if (!testPainter.didExceedMaxLines) {
            truncatedText = truncatedText.substring(0, endIndex);
            break;
          }
          endIndex--;
        }

        return RichText(
          textAlign: widget.textAlign,
          text: TextSpan(
            style: effectiveStyle,
            text: '$truncatedText...',
            children: [
              TextSpan(
                text: widget.showMoreText,
                style: widget.linkStyle,
                recognizer: TapGestureRecognizer()
                  ..onTap = () => setState(() => _isExpanded = true),
              ),
            ],
          ),
        );
      },
    );
  }
}
