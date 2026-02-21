import 'meal_log_model.dart';

class MealLogsResponse {
  final List<MealLogModel> content;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool last;
  final bool first;
  final int numberOfElements;
  final bool empty;

  MealLogsResponse({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.last,
    required this.first,
    required this.numberOfElements,
    required this.empty,
  });

  factory MealLogsResponse.fromJson(Map<String, dynamic> json) {
    return MealLogsResponse(
      content: (json["content"] as List<dynamic>)
          .map((e) => MealLogModel.fromJson(e))
          .toList(),
      pageNumber: json["pageable"]["pageNumber"],
      pageSize: json["pageable"]["pageSize"],
      totalElements: json["totalElements"],
      totalPages: json["totalPages"],
      last: json["last"],
      first: json["first"],
      numberOfElements: json["numberOfElements"],
      empty: json["empty"],
    );
  }
}
