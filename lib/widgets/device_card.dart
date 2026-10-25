import 'package:flutter/material.dart';
import '../models/device.dart';
import 'status_badge.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;
  final VoidCallback onQuickAction;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
    required this.onQuickAction,
  });

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'linux':
        return Icons.laptop_chromebook_rounded;
      case 'windows':
        return Icons.desktop_windows_rounded;
      case 'macos':
        return Icons.laptop_mac_rounded;
      case 'android':
        return Icons.smartphone_rounded;
      case 'ios':
        return Icons.phone_iphone_rounded;
      default:
        return Icons.devices_rounded;
    }
  }

  String _formatTimestamp(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Never';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOnline = device.isOnline;

    final iconBg = isOnline
        ? (isDark ? const Color(0xFF233930) : const Color(0xFFE6F4EC))
        : (isDark ? const Color(0xFF2B2838) : const Color(0xFFF2F0F8));
    final iconFg = isOnline
        ? (isDark ? const Color(0xFFA6E1C8) : const Color(0xFF2D664C))
        : theme.colorScheme.onSurfaceVariant;

    final platformLabel = device.platform.isEmpty
        ? 'Device'
        : '${device.platform[0].toUpperCase()}${device.platform.substring(1).toLowerCase()}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getPlatformIcon(device.platform),
                    color: iconFg,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$platformLabel · ${_formatTimestamp(device.lastSeenAt)}'
                        '${device.clipboardSyncEnabled ? " · Sync on" : ""}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: device.status),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
