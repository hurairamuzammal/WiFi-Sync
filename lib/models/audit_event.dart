class AuditEvent {
  final String id;
  final String userId;
  final String? deviceId;
  final String? commandId;
  final String eventType;
  final String createdAt;
  final Map<String, dynamic> metadata;

  AuditEvent({
    required this.id,
    required this.userId,
    this.deviceId,
    this.commandId,
    required this.eventType,
    required this.createdAt,
    required this.metadata,
  });

  factory AuditEvent.fromJson(Map<String, dynamic> json) {
    return AuditEvent(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      deviceId: json['device_id'] as String?,
      commandId: json['command_id'] as String?,
      eventType: json['event_type'] as String? ?? 'event',
      createdAt: json['created_at'] as String? ?? '',
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : {},
    );
  }
}
