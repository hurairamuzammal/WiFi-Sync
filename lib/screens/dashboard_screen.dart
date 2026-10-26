import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/device.dart';
import '../services/api_service.dart';
import '../services/background_sync_service.dart';
import '../services/clipboard_sync_manager.dart';
import '../services/firebase_service.dart';
import '../widgets/brand_logo_icon.dart';
import '../widgets/device_card.dart';
import 'device_detail_screen.dart';
import 'developer_screen.dart';
import 'command_history_screen.dart';
import 'pairing_dialog.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Device> _devices = [];
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;
  StreamSubscription<List<Device>>? _deviceSub;
  final ClipboardSyncManager _syncManager = ClipboardSyncManager();
  bool _accessibilityBannerDismissed = false;
  bool _accessibilityNeeded = false;

  @override
  void initState() {
    super.initState();
    _fetchDevices();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _checkAccessibilityStatus();
    }

    _syncManager.addListener(_onSyncStateChanged);
    _syncManager.onRemoteClipReceived = (item) {
      if (!mounted) return;
      ClipboardSyncManager.showSamsungPillToast(
        context,
        title: 'Synced from ${item.sourceDeviceId}',
        preview: item.text,
      );
    };
    _syncManager.start();

    if (ApiService().useFirebase && FirebaseService().isAuthenticated) {
      _deviceSub = FirebaseService().devicesStream().listen((list) {
        if (mounted) {
          setState(() {
            _devices = list;
            _isLoading = false;
          });
        }
      });
    }

    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted &&
          (!ApiService().useFirebase || !FirebaseService().isAuthenticated)) {
        _fetchDevices(isSilent: true);
      }
    });
  }

  void _onSyncStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _checkAccessibilityStatus() async {
    final enabled = await BackgroundSyncService().isAccessibilityEnabled();
    if (mounted) {
      setState(() {
        _accessibilityNeeded = !enabled;
      });
    }
  }

  @override
  void dispose() {
    _syncManager.removeListener(_onSyncStateChanged);
    _deviceSub?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDevices({bool isSilent = false}) async {
    if (!isSilent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final list = await ApiService().getDevices();
      if (mounted) {
        setState(() {
          _devices = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _openDeviceDetail(Device device) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DeviceDetailScreen(device: device),
      ),
    );
    if (changed == true) {
      _fetchDevices();
    }
  }

  void _openPairingDialog() async {
    final paired = await PairingDialog.show(context);
    if (paired == true) {
      _fetchDevices();
    }
  }

  Future<void> _manualPushClipboard() async {
    final ok = await _syncManager.pushClipboardNow();
    if (!mounted) return;
    if (ok) {
      final latest = _syncManager.latestItem?.text ?? '';
      ClipboardSyncManager.showSamsungPillToast(
        context,
        title: 'Clipboard sent',
        preview: latest,
        icon: Icons.check_rounded,
      );
    } else {
      ClipboardSyncManager.showSamsungPillToast(
        context,
        title: 'Clipboard is empty',
        preview: 'Copy text first or open the Clipboard Hub',
        icon: Icons.info_outline_rounded,
      );
    }
  }

  void _openClipboardHubSheet() {
    _syncManager.markRead();
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final theme = Theme.of(ctx);
            final history = _syncManager.history;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.content_paste_rounded,
                            size: 18,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clipboard Sync',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _syncManager.autoSyncEnabled
                                    ? 'Automatic sync enabled'
                                    : 'Manual sync only',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _syncManager.autoSyncEnabled,
                          onChanged: (v) {
                            _syncManager.setAutoSync(v);
                            setSheetState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            decoration: const InputDecoration(
                              hintText: 'Paste or type text to send...',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            final custom = textController.text.trim();
                            final ok = await _syncManager.pushClipboardNow(
                              customText: custom.isEmpty ? null : custom,
                            );
                            textController.clear();
                            setSheetState(() {});
                            if (mounted && ok) {
                              ClipboardSyncManager.showSamsungPillToast(
                                context,
                                title: 'Sent to devices',
                                preview: _syncManager.latestItem?.text ?? '',
                                icon: Icons.send_rounded,
                              );
                            }
                          },
                          child: const Text('Send'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (history.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'No recent clipboard items yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12.5,
                          ),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: history.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (_, idx) {
                            final item = history[idx];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                item.isIncoming
                                    ? Icons.south_west_rounded
                                    : Icons.north_east_rounded,
                                color: item.isIncoming
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.primary,
                                size: 18,
                              ),
                              title: Text(
                                item.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                item.sourceDeviceId,
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 17),
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: item.text));
                                  Navigator.of(ctx).pop();
                                  ClipboardSyncManager.showSamsungPillToast(
                                    context,
                                    title: 'Copied',
                                    preview: item.text,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onlineCount = _devices.where((d) => d.isOnline).length;
    final hasUnread = _syncManager.hasUnreadClip;
    final latestClip = _syncManager.latestItem;

    // Soft pastel-harmonious indicator colors for the top-right clipboard icon
    final Color clipStatusColor =
        (_error != null || !_syncManager.autoSyncEnabled)
            ? const Color(0xFFE56B6F)
            : (hasUnread || onlineCount == 0)
                ? const Color(0xFFE5A922)
                : const Color(0xFF34C77B);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BrandLogoIcon(size: 30),
            const SizedBox(width: 10),
            const Text(
              'ClipSync',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: hasUnread ? 'New synced clip' : 'Clipboard Sync',
            onPressed: _openClipboardHubSheet,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.content_paste_rounded,
                  size: 21,
                  color: theme.colorScheme.onSurface,
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: clipStatusColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded),
            tooltip: 'Menu',
            onSelected: (value) {
              if (value == 'history') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const CommandHistoryScreen()),
                );
              } else if (value == 'developer') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DeveloperScreen()),
                );
              } else if (value == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'history',
                child: Text('Activity History'),
              ),
              PopupMenuItem(
                value: 'developer',
                child: Text('About'),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off_rounded,
                            size: 44, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonal(
                          onPressed: () => _fetchDevices(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _fetchDevices(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: ListView(
                        padding:
                            const EdgeInsets.fromLTRB(20, 12, 20, 96),
                        children: [
                          // Android Accessibility Setup Banner
                          if (_accessibilityNeeded && !_accessibilityBannerDismissed) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF322718)
                                    : const Color(0xFFFFF9E6),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF6E5322)
                                      : const Color(0xFFFFD591),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.accessibility_new_rounded,
                                    size: 20,
                                    color: Color(0xFFD46B08),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Background sync needs Accessibility',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          'Required on Android 10+ to detect copied text across apps.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                    ),
                                    onPressed: () async {
                                      await BackgroundSyncService()
                                          .openAccessibilitySettings();
                                      await Future.delayed(
                                          const Duration(seconds: 1));
                                      _checkAccessibilityStatus();
                                    },
                                    child: const Text('Enable',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      setState(() {
                                        _accessibilityBannerDismissed = true;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Minimal Flat Pastel Sync Strip
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF252234)
                                  : const Color(0xFFEFECFA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF36314A)
                                    : const Color(0xFFE1DBF3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: clipStatusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _devices.isEmpty
                                                ? 'Waiting for paired device'
                                                : (onlineCount > 0
                                                    ? '${_devices.first.displayName} is online'
                                                    : '${_devices.first.displayName} is offline'),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _syncManager.autoSyncEnabled
                                                ? 'Clipboard syncs automatically'
                                                : 'Manual clipboard sync',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        backgroundColor: isDark
                                            ? const Color(0xFF332E47)
                                            : Colors.white,
                                        foregroundColor:
                                            theme.colorScheme.primary,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(11),
                                        ),
                                      ),
                                      onPressed: _manualPushClipboard,
                                      icon: const Icon(
                                          Icons.north_east_rounded,
                                          size: 15),
                                      label: const Text(
                                        'Send Clip',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (latestClip != null) ...[
                                  const SizedBox(height: 12),
                                  InkWell(
                                    onTap: _openClipboardHubSheet,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E1C2A)
                                            : Colors.white.withValues(alpha: 0.78),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.notes_rounded,
                                            size: 15,
                                            color: theme.colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              latestClip.text,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              'PAIRED DEVICES',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (_devices.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 40),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: theme.colorScheme.outlineVariant),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.devices_outlined,
                                    size: 40,
                                    color: theme.colorScheme.outline,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No devices paired yet',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Pair your Linux desktop using a one-time code.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._devices.map(
                              (device) => DeviceCard(
                                device: device,
                                onTap: () => _openDeviceDetail(device),
                                onQuickAction: () => _openDeviceDetail(device),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPairingDialog,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Pair Device',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}
