class DeviceCommand {
  final String id;
  final String userId;
  final String deviceId;
  final String action;
  final String status;
  final String createdAt;
  final String expiresAt;
  final String? acceptedAt;
  final String? finishedAt;
  final String? errorCode;
  final String? resultSummary;

  DeviceCommand({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.action,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.acceptedAt,
    this.finishedAt,
    this.errorCode,
    this.resultSummary,
  });

  factory DeviceCommand.fromJson(Map<String, dynamic> json) {
    return DeviceCommand(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      deviceId: json['device_id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] as String? ?? '',
      expiresAt: json['expires_at'] as String? ?? '',
      acceptedAt: json['accepted_at'] as String?,
      finishedAt: json['finished_at'] as String?,
      errorCode: json['error_code'] as String?,
      resultSummary: json['result_summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'action': action,
      'status': status,
      'created_at': createdAt,
      'expires_at': expiresAt,
      'accepted_at': acceptedAt,
      'finished_at': finishedAt,
      'error_code': errorCode,
      'result_summary': resultSummary,
    };
  }
}
