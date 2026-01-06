class BaseResponse<T> {
  final bool success;
  final String message;
  final T? data;

  BaseResponse({
    required this.success,
    this.message = '',
    this.data,
  });

  factory BaseResponse.fromJson(
    Map<String, dynamic> json, [
    T Function(dynamic json)? fromJsonT,
  ]) {
    return BaseResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] != null && fromJsonT != null)
          ? fromJsonT(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data,
    };
  }
}