import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/utils/secure_storage_utils.dart';

import '../../models/notification/notification_model.dart';
import '../../services/notification_service.dart';
import '../token_provider.dart';

/// Pagination constants
const int firstPageSize = 50;
const int pageSize = 50;

/// ----------------------------
/// STATE
/// ----------------------------
class NotificationState {
  final List<NotificationItem> notifications;
  final bool isLoading;
  final bool hasMore;
  final int unseenCount;
  final String searchQuery;
  final int page;

  NotificationState({
    required this.notifications,
    this.isLoading = false,
    this.hasMore = true,
    this.unseenCount = 0,
    this.searchQuery = '',
    this.page = 0,
  });

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    bool? isLoading,
    bool? hasMore,
    int? unseenCount,
    int? page,
    String? searchQuery,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      unseenCount: unseenCount ?? this.unseenCount,
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
    );
  }
}

/// ----------------------------
/// NOTIFIER
/// ----------------------------
class NotificationNotifier extends StateNotifier<NotificationState> {
  final Ref ref;

  NotificationNotifier(this.ref)
      : super(NotificationState(notifications: []));

  /// 🔹 Load First Page (100 notifications)
  Future<void> loadFirstPage() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, page: 0);

    //final token = ref.watch(tokenProvider);
    final token = await SecureStorageUtils().read(StorageKeys.accessToken);

    final list = await NotificationService.fetchNotifications(
      page: 0,
      size: firstPageSize,
      token: token!,
    );
    debugPrint('$list');
    state = state.copyWith(
      notifications: list,
      unseenCount: list.where((e) => !e.seen).length,
      hasMore: list.length == firstPageSize,
      isLoading: false,
      page: 0,
    );
  }
  Future<void> loadFirstPageNew() async {


    //state = state.copyWith(isLoading: true, page: 0);

    final token = ref.read(tokenProvider);

    final list = await NotificationService.fetchNotifications(
      page: 0,
      size: firstPageSize,
      token: token!,
    );
    debugPrint("$list");
    state = state.copyWith(
      notifications: list,
      unseenCount: list.where((e) => !e.seen).length,
      hasMore: list.length == firstPageSize,
      isLoading: false,
      page: 0,
    );
  }

  /// 🔹 Load Next Page (50 notifications)
  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    final nextPage = state.page + 1;
    final token = ref.read(tokenProvider);

    final list = await NotificationService.fetchNotifications(
      page: nextPage,
      size: pageSize,
      token: token!,
    );

    final allNotifications = [...state.notifications, ...list];

    state = state.copyWith(
      notifications: allNotifications,
      unseenCount: allNotifications.where((e) => !e.seen).length,
      hasMore: list.length == pageSize,
      isLoading: false,
      page: nextPage,
    );
  }

  /// 🔹 Pull-to-refresh
  Future<void> refresh() async {
    await loadFirstPage();
  }

  /// 🔹 Search
  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query.toLowerCase());
  }

  List<NotificationItem> get filteredNotifications {
    if (state.searchQuery.isEmpty) return state.notifications;

    return state.notifications.where((n) {
      return n.title.toLowerCase().contains(state.searchQuery) ||
          n.message.toLowerCase().contains(state.searchQuery);
    }).toList();
  }

  /// 🔹 Mark single notification as seen
  Future<void> markNotificationAsSeen(String uuid) async {
    final token = ref.read(tokenProvider);

    final success = await NotificationService.markSeen(token!, [uuid]);
    if (!success) return;

    final now = DateTime.now();

    final updatedList = state.notifications.map((n) {
      if (n.uuid == uuid && !n.seen) {
        return n.copyWith(seen: true, seenAt: now);
      }
      return n;
    }).toList();

    state = state.copyWith(
      notifications: updatedList,
      unseenCount: updatedList.where((e) => !e.seen).length,
    );
  }

  /// 🔹 Mark ALL notifications as seen
  Future<void> markAllNotificationAsSeen(List<String> uuids) async {
    if (uuids.isEmpty) return;

    final token = ref.read(tokenProvider);

    final success = await NotificationService.markSeen(token!, uuids);
    if (!success) return;

    final uuidSet = uuids.toSet();
    final now = DateTime.now();

    final updatedList = state.notifications.map((n) {
      if (uuidSet.contains(n.uuid) && !n.seen) {
        return n.copyWith(seen: true, seenAt: now);
      }
      return n;
    }).toList();

    state = state.copyWith(
      notifications: updatedList,
      unseenCount: updatedList.where((e) => !e.seen).length,
    );
  }
}

/// ----------------------------
/// PROVIDER
/// ----------------------------
final notificationProvider =
StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});
