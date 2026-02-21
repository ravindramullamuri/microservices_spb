class ApiResponse<T> {
  final int status;
  final bool success;
  final T? data;
  final String? error;
  final String? message;

  ApiResponse({
    required this.status,
    required this.success,
    this.data,
    this.error,
    this.message,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return ApiResponse(
      status: json['status'],
      success: json['success'],
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      error: json['error'] as String?,
      message: json['message'] as String?,
    );
  }
}