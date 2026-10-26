import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/background_sync_service.dart';
import '../services/clipboard_sync_manager.dart';
import '../services/firebase_service.dart';
import '../widgets/brand_logo_icon.dart';
import '../widgets/google_logo_icon.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/status_badge.dart';
import 'auth_screen.dart';
import 'developer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _emulatorHostController;
  bool _useFirebase = true;
  bool _useEmulator = false;
  bool _autoSync = true;
  bool _isAndroid = false;
  bool _accessibilityEnabled = false;
  bool _batteryOptIgnored = false;
  bool _foregroundServiceActive = false;

  @override
  void initState() {
    super.initState();
    _useFirebase = ApiService().useFirebase;
    _useEmulator = FirebaseService().useEmulator;
    _autoSync = ClipboardSyncManager().isClipboardSyncActive;
    _emulatorHostController =
        TextEditingController(text: FirebaseService().emulatorHost);
    _isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (_isAndroid) {
      _checkAndroidPermissions();
    }
  }

  Future<void> _checkAndroidPermissions() async {
    final acc = await BackgroundSyncService().isAccessibilityEnabled();
    final batt = await BackgroundSyncService().isBatteryOptimizationIgnored();
    final fg = await BackgroundSyncService().isForegroundServiceRunning();
    if (mounted) {
      setState(() {
        _accessibilityEnabled = acc;
        _batteryOptIgnored = batt;
        _foregroundServiceActive = fg;
      });
    }
  }

  @override
  void dispose() {
    _emulatorHostController.dispose();
    super.dispose();
  }

  Future<void> _handleToggleAutoSync(bool value) async {
    await ClipboardSyncManager().setClipboardSyncActive(value);
    await _checkAndroidPermissions();
    if (mounted) {
      setState(() => _autoSync = value);
    }
  }

  Future<void> _handleToggleFirebase(bool value) async {
    await ApiService().setUseFirebase(value);
    setState(() => _useFirebase = value);
  }

  Future<void> _handleToggleEmulator(bool value) async {
    await FirebaseService()
        .setUseEmulator(value, host: _emulatorHostController.text.trim());
    setState(() => _useEmulator = value);
  }

  Future<void> _handleResetPassword() async {
    final email = ApiService().currentUserEmail;
    if (email == null || email.isEmpty) return;

    try {
      await ApiService().sendPasswordResetEmail(email);
      if (!mounted) return;
      ClipboardSyncManager.showSamsungPillToast(
        context,
        title: 'Reset link sent',
        preview: email,
        icon: Icons.mark_email_read_outlined,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _handleLogout() async {
    ClipboardSyncManager().stop();
    await ApiService().logOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleForgetDeviceSession() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Forget Device Session',
      message:
          'Clear all locally saved credentials, tokens, and disconnect clipboard sync on this device?',
      confirmLabel: 'Forget & Sign Out',
      confirmColor: const Color(0xFFD95C63),
      icon: Icons.phonelink_erase_rounded,
    );
    if (!confirmed) return;

    ClipboardSyncManager().stop();
    await ApiService().forgetDeviceSession();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  Widget _sectionLabel(ThemeData theme, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userEmail = ApiService().currentUserEmail ?? 'Not signed in';
    final isEmailAccount = ApiService().isEmailPasswordAccount;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Minimal Pastel Brand & Version Card
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DeveloperScreen()),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF282438)
                        : const Color(0xFFEFECFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF393450)
                          : const Color(0xFFE0DAF2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const BrandLogoIcon(size: 44),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'ClipSync',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF243B32)
                                        : const Color(0xFFDDF2E8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'v${DeveloperScreen.appVersion}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFFA6E1C8)
                                          : const Color(0xFF2B6349),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DeveloperScreen.developerName,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Account
              _sectionLabel(theme, 'Account'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        radius: 19,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        userEmail,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        isEmailAccount ? 'Email account' : 'Google account',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.65),
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _handleLogout,
                        child: const Text(
                          'Sign out',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    if (isEmailAccount) ...[
                      const Divider(),
                      ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 2),
                        leading: Icon(
                          Icons.lock_reset_rounded,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text(
                          'Reset password',
                          style: TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text(
                          'Send password reset email link',
                          style: TextStyle(fontSize: 11.5),
                        ),
                        trailing: TextButton(
                          onPressed: _handleResetPassword,
                          child: const Text(
                            'Send link',
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ),
                    ] else ...[
                      const Divider(),
                      ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 2),
                        leading: const GoogleLogoIcon(size: 19),
                        title: const Text(
                          'Google Account Security',
                          style: TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text(
                          'Password and authentication managed by Google OAuth',
                          style: TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ],
                    const Divider(),
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      leading: Icon(
                        Icons.phonelink_erase_rounded,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        'Forget this device session',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      subtitle: const Text(
                        'Clear local credentials, tokens, and active clipboard sync',
                        style: TextStyle(fontSize: 11.5),
                      ),
                      trailing: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        onPressed: _handleForgetDeviceSession,
                        child: const Text(
                          'Forget',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sync & Cloud
              _sectionLabel(theme, 'Sync & Cloud'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      title: const Text(
                        'Clipboard sync',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text(
                        'Background service & internet sync across devices',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _autoSync,
                      onChanged: _handleToggleAutoSync,
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      title: const Text(
                        'Realtime cloud sync',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text(
                        'Firebase Realtime Database stream',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _useFirebase,
                      onChanged: _handleToggleFirebase,
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      title: const Text(
                        'Local emulator',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text(
                        'Use localhost ports 9099 / 9000 for offline testing',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _useEmulator,
                      onChanged: _useFirebase ? _handleToggleEmulator : null,
                    ),
                    if (_useEmulator)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                        child: TextField(
                          controller: _emulatorHostController,
                          decoration: const InputDecoration(
                            labelText: 'Emulator host',
                            hintText: '127.0.0.1',
                            isDense: true,
                          ),
                          onSubmitted: (_) => _handleToggleEmulator(true),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Android Background Keep-Alive & Accessibility Permissions
              if (_isAndroid) ...[
                _sectionLabel(theme, 'Android Background Sync & Keep-Alive'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _accessibilityEnabled
                                ? const Color(0xFFE4F4EC)
                                : const Color(0xFFFCF1DF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.accessibility_new_rounded,
                            size: 20,
                            color: _accessibilityEnabled
                                ? const Color(0xFF285E45)
                                : const Color(0xFF7D561E),
                          ),
                        ),
                        title: const Text(
                          'Accessibility Copy Detector',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          _accessibilityEnabled
                              ? 'Active · Captures copied text instantly across all apps'
                              : 'Bypasses Android 10+ background clipboard restrictions',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: _accessibilityEnabled
                            ? const StatusBadge(status: 'Active')
                            : FilledButton.tonal(
                                onPressed: () async {
                                  await BackgroundSyncService()
                                      .openAccessibilitySettings();
                                  Future.delayed(const Duration(seconds: 1),
                                      _checkAndroidPermissions);
                                },
                                child: const Text('Enable',
                                    style: TextStyle(fontSize: 12)),
                              ),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _batteryOptIgnored
                                ? const Color(0xFFE4F4EC)
                                : const Color(0xFFFCF1DF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.battery_charging_full_rounded,
                            size: 20,
                            color: _batteryOptIgnored
                                ? const Color(0xFF285E45)
                                : const Color(0xFF7D561E),
                          ),
                        ),
                        title: const Text(
                          'Battery Optimization Exemption',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          _batteryOptIgnored
                              ? 'Unrestricted · Samsung One UI will not sleep background sync'
                              : 'Prevents OS from sleeping the background sync socket',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: _batteryOptIgnored
                            ? const StatusBadge(status: 'Optimized')
                            : FilledButton.tonal(
                                onPressed: () async {
                                  await BackgroundSyncService()
                                      .requestIgnoreBatteryOptimization();
                                  Future.delayed(const Duration(seconds: 1),
                                      _checkAndroidPermissions);
                                },
                                child: const Text('Disable',
                                    style: TextStyle(fontSize: 12)),
                              ),
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 2),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECE8F8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.notifications_active_outlined,
                            size: 20,
                            color: Color(0xFF423869),
                          ),
                        ),
                        title: const Text(
                          'Foreground Keep-Alive Service',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        subtitle: const Text(
                          'Shows ongoing notification to keep sub-second sync permanently awake',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _foregroundServiceActive,
                        onChanged: (val) async {
                          if (val) {
                            await BackgroundSyncService().startForegroundSync();
                          } else {
                            await BackgroundSyncService().stopForegroundSync();
                          }
                          await _checkAndroidPermissions();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
