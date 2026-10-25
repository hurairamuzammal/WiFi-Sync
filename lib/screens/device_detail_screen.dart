import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/device.dart';
import '../models/command.dart';
import '../services/api_service.dart';
import '../services/clipboard_sync_manager.dart';
import '../services/firebase_service.dart';
import '../widgets/status_badge.dart';
import '../widgets/confirmation_dialog.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  late Device _device;
  bool _isPerformingAction = false;
  String? _statusBanner;
  Color _statusBannerBg = const Color(0xFFE5F5ED);
  Color _statusBannerFg = const Color(0xFF2A664B);
  String? _activeCommandId;
  String? _lastClipboardText;
  String? _lastEventId;
  final TextEditingController _clipboardController = TextEditingController();

  StreamSubscription<List<Device>>? _deviceSub;
  StreamSubscription<List<DeviceCommand>>? _commandSub;
  StreamSubscription<Map<String, dynamic>?>? _clipboardSub;

  @override
  void initState() {
    super.initState();
    _device = widget.device;

    if (ApiService().useFirebase && FirebaseService().isAuthenticated) {
      _deviceSub = FirebaseService().devicesStream().listen((devices) {
        final match = devices.where((d) => d.id == _device.id).toList();
        if (match.isNotEmpty && mounted) {
          setState(() => _device = match.first);
        }
      });

      _commandSub = FirebaseService().commandsStream().listen((commands) {
        if (_activeCommandId == null || !mounted) return;
        final match = commands.where((c) => c.id == _activeCommandId).toList();
        if (match.isNotEmpty) {
          final cmd = match.first;
          setState(() {
            if (cmd.status == 'succeeded') {
              _statusBanner = '${cmd.action}: ${cmd.resultSummary ?? "Done"}';
              _statusBannerBg = const Color(0xFFE5F5ED);
              _statusBannerFg = const Color(0xFF2A664B);
            } else if (cmd.status == 'accepted') {
              _statusBanner = 'Running ${cmd.action} on ${_device.displayName}...';
              _statusBannerBg = const Color(0xFFECE8F8);
              _statusBannerFg = const Color(0xFF3E3563);
            } else if (cmd.status == 'failed' || cmd.status == 'expired') {
              _statusBanner =
                  '${cmd.action} ${cmd.status}: ${cmd.resultSummary ?? cmd.errorCode ?? ""}';
              _statusBannerBg = const Color(0xFFFCEBEC);
              _statusBannerFg = const Color(0xFF94383C);
            }
          });
        }
      });

      _clipboardSub = FirebaseService().clipboardStream().listen((evt) {
        if (evt == null || !mounted || !_device.clipboardSyncEnabled) return;
        final text = evt['text'] as String?;
        final src = evt['sourceDeviceId'] as String?;
        final createdAt = evt['createdAt']?.toString();
        if (text != null &&
            text.isNotEmpty &&
            src != 'flutter-client' &&
            createdAt != _lastEventId) {
          _lastEventId = createdAt;
          Clipboard.setData(ClipboardData(text: text));
          setState(() {
            _lastClipboardText = text;
            _clipboardController.text = text;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _deviceSub?.cancel();
    _commandSub?.cancel();
    _clipboardSub?.cancel();
    _clipboardController.dispose();
    super.dispose();
  }

  Future<void> _sendClipboardToDevice({String? customText}) async {
    try {
      String? textToSend = customText?.trim();
      if (textToSend == null || textToSend.isEmpty) {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        textToSend = data?.text?.trim();
      }
      if (textToSend == null || textToSend.isEmpty) {
        if (mounted) {
          ClipboardSyncManager.showSamsungPillToast(
            context,
            title: 'Clipboard is empty',
            preview: 'Copy or enter text first',
          );
        }
        return;
      }

      final ok = await ClipboardSyncManager().pushClipboardNow(
        customText: textToSend,
      );
      if (mounted && ok) {
        setState(() => _lastClipboardText = textToSend);
        ClipboardSyncManager.showSamsungPillToast(
          context,
          title: 'Sent to ${_device.displayName}',
          preview: textToSend,
          icon: Icons.send_rounded,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sync clipboard: $e')),
        );
      }
    }
  }

  Future<void> _toggleClipboardSync(bool enabled) async {
    try {
      final updated = await ApiService().updateDevice(
        _device.id,
        clipboardSyncEnabled: enabled,
      );
      setState(() => _device = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update sync setting: $e')),
        );
      }
    }
  }

  Future<void> _handleRename() async {
    final controller = TextEditingController(text: _device.displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Device'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Device Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null &&
        newName.isNotEmpty &&
        newName != _device.displayName) {
      final updated =
          await ApiService().updateDevice(_device.id, displayName: newName);
      if (mounted) setState(() => _device = updated);
    }
  }

  Future<void> _handleRevoke() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Forget Device',
      message:
          'Forget and remove "${_device.displayName}" from your synced devices?',
      confirmLabel: 'Forget Device',
      confirmColor: const Color(0xFFD95C63),
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed) {
      await ApiService().revokeDevice(_device.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  Future<void> _handlePowerAction(String action) async {
    String title;
    String message;
    Color actionColor = const Color(0xFF5D5094);

    switch (action) {
      case 'shutdown':
        title = 'Shut Down';
        message = 'Power off "${_device.displayName}"?';
        actionColor = const Color(0xFFC95057);
        break;
      case 'restart':
        title = 'Restart';
        message = 'Reboot "${_device.displayName}"?';
        actionColor = const Color(0xFFB57A2A);
        break;
      case 'sleep':
        title = 'Sleep';
        message = 'Put "${_device.displayName}" to sleep?';
        actionColor = const Color(0xFF5D5094);
        break;
      case 'health_check':
        title = 'Health Check';
        message = 'Check uptime and system status of "${_device.displayName}"?';
        actionColor = const Color(0xFF39765C);
        break;
      default:
        return;
    }

    final confirmed = await ConfirmationDialog.show(
      context,
      title: title,
      message: message,
      confirmLabel: 'Confirm',
      confirmColor: actionColor,
      icon: Icons.power_settings_new_rounded,
    );

    if (!confirmed) return;

    setState(() {
      _isPerformingAction = true;
      _statusBanner = null;
    });

    try {
      final cmd = await ApiService().sendCommand(
        deviceId: _device.id,
        action: action,
        ttlSeconds: 60,
      );

      setState(() {
        _activeCommandId = cmd.id;
        _statusBanner = 'Sent "$action" (${cmd.status})';
        _statusBannerBg = const Color(0xFFECE8F8);
        _statusBannerFg = const Color(0xFF3E3563);
      });
    } catch (e) {
      setState(() {
        _statusBanner = 'Failed: $e';
        _statusBannerBg = const Color(0xFFFCEBEC);
        _statusBannerFg = const Color(0xFF94383C);
      });
    } finally {
      if (mounted) setState(() => _isPerformingAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _device.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (val) {
              if (val == 'rename') _handleRename();
              if (val == 'revoke') _handleRevoke();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'revoke', child: Text('Forget / Remove device')),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              if (_statusBanner != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: _statusBannerBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusBanner!,
                    style: TextStyle(
                      color: _statusBannerFg,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),

              // Minimal Overview Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _device.platform.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          StatusBadge(status: _device.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 10),
                      _infoRow(theme, 'ID', _device.id),
                      _infoRow(
                          theme, 'Version', _device.agentVersion ?? '2.1.0'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Minimal Clipboard Card
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      title: const Text(
                        'Clipboard Sync',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Share copied text with this device',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _device.clipboardSyncEnabled,
                      onChanged: _toggleClipboardSync,
                    ),
                    if (_device.clipboardSyncEnabled) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _clipboardController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText: 'Paste or type text to send...',
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => _sendClipboardToDevice(
                                      customText: _clipboardController.text,
                                    ),
                                    child: const Text('Send Text'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.tonal(
                                    onPressed: () => _sendClipboardToDevice(),
                                    child: const Text('Push Clipboard'),
                                  ),
                                ),
                              ],
                            ),
                            if (_lastClipboardText != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Latest: $_lastClipboardText',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (const ['linux', 'windows', 'macos']
                  .contains(_device.platform.toLowerCase())) ...[
                const SizedBox(height: 22),

                // Minimal Pastel Actions Grid / List (Desktop Agents Only)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'REMOTE ACTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _pastelActionButton(
                        context,
                        label: 'Health Check',
                        icon: Icons.favorite_border_rounded,
                        pastelBg: const Color(0xFFE4F4EC),
                        pastelFg: const Color(0xFF285E45),
                        onTap: () => _handlePowerAction('health_check'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _pastelActionButton(
                        context,
                        label: 'Sleep',
                        icon: Icons.bedtime_outlined,
                        pastelBg: const Color(0xFFECE8F8),
                        pastelFg: const Color(0xFF423869),
                        onTap: () => _handlePowerAction('sleep'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _pastelActionButton(
                        context,
                        label: 'Restart',
                        icon: Icons.restart_alt_rounded,
                        pastelBg: const Color(0xFFFCF1DF),
                        pastelFg: const Color(0xFF7D561E),
                        onTap: () => _handlePowerAction('restart'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _pastelActionButton(
                        context,
                        label: 'Shut Down',
                        icon: Icons.power_settings_new_rounded,
                        pastelBg: const Color(0xFFFCEBEC),
                        pastelFg: const Color(0xFF8F373B),
                        onTap: () => _handlePowerAction('shutdown'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pastelActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color pastelBg,
    required Color pastelFg,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _isPerformingAction ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252331) : pastelBg,
          borderRadius: BorderRadius.circular(14),
          border: isDark
              ? Border.all(color: const Color(0xFF343045))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? const Color(0xFFD6CFF2) : pastelFg,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: isDark ? const Color(0xFFECEAF4) : pastelFg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
