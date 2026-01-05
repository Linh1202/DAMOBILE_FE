class BaseResponse<T> {
  late bool success;
  late String message;
  late T data;

  BaseResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory BaseResponse.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic json) fromJsonT,
      ) {
    return BaseResponse(
      success: json['success'],
      message: json['message'],
      data: fromJsonT(json['data']),
    );
  }
}