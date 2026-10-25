class Device {
  final String id;
  final String userId;
  final String displayName;
  final String platform;
  final String? agentVersion;
  final String createdAt;
  final String? lastSeenAt;
  final String status;
  final String? revokedAt;
  final bool clipboardSyncEnabled;

  Device({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.platform,
    this.agentVersion,
    required this.createdAt,
    this.lastSeenAt,
    required this.status,
    this.revokedAt,
    required this.clipboardSyncEnabled,
  });

  bool get isOnline => status.toLowerCase() == 'online';
  bool get isRevoked => revokedAt != null && revokedAt!.isNotEmpty;

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Unnamed Device',
      platform: (json['platform'] as String? ?? 'linux').toLowerCase(),
      agentVersion: json['agent_version'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      lastSeenAt: json['last_seen_at'] as String?,
      status: json['status'] as String? ?? 'offline',
      revokedAt: json['revoked_at'] as String?,
      clipboardSyncEnabled: json['clipboard_sync_enabled'] == true ||
          json['clipboard_sync_enabled'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'platform': platform,
      'agent_version': agentVersion,
      'created_at': createdAt,
      'last_seen_at': lastSeenAt,
      'status': status,
      'revoked_at': revokedAt,
      'clipboard_sync_enabled': clipboardSyncEnabled,
    };
  }

  Device copyWith({
    String? displayName,
    String? status,
    String? lastSeenAt,
    bool? clipboardSyncEnabled,
    String? revokedAt,
  }) {
    return Device(
      id: id,
      userId: userId,
      displayName: displayName ?? this.displayName,
      platform: platform,
      agentVersion: agentVersion,
      createdAt: createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      status: status ?? this.status,
      revokedAt: revokedAt ?? this.revokedAt,
      clipboardSyncEnabled:
          clipboardSyncEnabled ?? this.clipboardSyncEnabled,
    );
  }
}
