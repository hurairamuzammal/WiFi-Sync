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
import 'legal_and_faq_screen.dart';

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

  Future<void> _handleClearCloudClipboard() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Clear Cloud Clipboard',
      message:
          'Permanently remove all synchronized clipboard history from your Firebase database? Local device clipboards will remain untouched.',
      confirmLabel: 'Clear Cloud Data',
      confirmColor: const Color(0xFFD95C63),
      icon: Icons.delete_sweep_outlined,
    );
    if (!confirmed) return;

    try {
      await ApiService().clearCloudClipboardHistory();
      if (!mounted) return;
      ClipboardSyncManager.showSamsungPillToast(
        context,
        title: 'Cloud History Cleared',
        preview: 'All remote clipboard entries wiped',
        icon: Icons.check_circle_outline_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear clipboard: $e')),
      );
    }
  }

  Future<void> _handleDeleteAccountAndData() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Account & Wipe Data',
      message:
          'GDPR Article 17: Right to Erasure.\n\nThis permanently destroys your user account, device registrations, and cloud clipboard events from Firebase. This action CANNOT be undone.',
      confirmLabel: 'Permanently Delete',
      confirmColor: const Color(0xFFD95C63),
      icon: Icons.warning_amber_rounded,
    );
    if (!confirmed) return;

    ClipboardSyncManager().stop();
    try {
      await ApiService().deleteAccountAndData();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: $e')),
      );
    }
  }

  void _showFirebaseConfigDialog() {
    final fb = FirebaseService();
    final initialProj = fb.customProjectId ??
        (fb.activeProjectId.startsWith('your-') ? '' : fb.activeProjectId);
    final initialKey = fb.customApiKey ??
        (fb.activeApiKey.startsWith('YOUR_') ? '' : fb.activeApiKey);
    final initialUrl = fb.customDatabaseUrl ??
        (fb.activeDatabaseUrl.contains('your-') ? '' : fb.activeDatabaseUrl);

    final projController = TextEditingController(text: initialProj);
    final keyController = TextEditingController(text: initialKey);
    final urlController = TextEditingController(text: initialUrl);

    bool isTesting = false;
    String? testResult;
    bool? testSuccess;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = Theme.of(ctx);
          final insets = MediaQuery.of(ctx).viewInsets.bottom;

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + insets),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.cloud_sync_outlined,
                            color: theme.colorScheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connect Your Free Firebase',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Use your personal free cloud tier (\$0 cost)',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: projController,
                    decoration: const InputDecoration(
                      labelText: 'Firebase Project ID',
                      hintText: 'e.g. my-wifisync-free',
                      isDense: true,
                      prefixIcon: Icon(Icons.folder_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keyController,
                    decoration: const InputDecoration(
                      labelText: 'Web / REST API Key',
                      hintText: 'e.g. AIzaSy...',
                      isDense: true,
                      prefixIcon: Icon(Icons.key_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'Database URL (optional)',
                      hintText: 'https://<project-id>-default-rtdb.firebaseio.com',
                      isDense: true,
                      prefixIcon: Icon(Icons.link_outlined, size: 20),
                    ),
                  ),
                  if (testResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: (testSuccess ?? false)
                            ? const Color(0xFFE4F4EC)
                            : const Color(0xFFFDE8E8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            (testSuccess ?? false)
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: (testSuccess ?? false)
                                ? const Color(0xFF285E45)
                                : const Color(0xFFD95C63),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              testResult!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: (testSuccess ?? false)
                                    ? const Color(0xFF285E45)
                                    : const Color(0xFFD95C63),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isTesting
                              ? null
                              : () async {
                                  final p = projController.text.trim();
                                  final k = keyController.text.trim();
                                  final u = urlController.text.trim();
                                  if (p.isEmpty || k.isEmpty) {
                                    setModalState(() {
                                      testResult =
                                          'Project ID and API Key required';
                                      testSuccess = false;
                                    });
                                    return;
                                  }
                                  setModalState(() {
                                    isTesting = true;
                                    testResult = null;
                                  });
                                  final ok = await fb.testFirebaseConnection(
                                    projectId: p,
                                    apiKey: k,
                                    databaseUrl: u,
                                  );
                                  setModalState(() {
                                    isTesting = false;
                                    testSuccess = ok;
                                    testResult = ok
                                        ? 'Connection successful! Database reachable.'
                                        : 'Could not connect. Verify API Key and Project ID.';
                                  });
                                },
                          child: isTesting
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Test Connection'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final p = projController.text.trim();
                            final k = keyController.text.trim();
                            final u = urlController.text.trim();
                            if (p.isEmpty || k.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Please enter Project ID and API Key')),
                              );
                              return;
                            }
                            await fb.saveCustomFirebaseConfig(
                              projectId: p,
                              apiKey: k,
                              databaseUrl: u,
                            );
                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop();
                            setState(() {});
                            if (mounted) {
                              ClipboardSyncManager.showSamsungPillToast(
                                context,
                                title: 'Cloud Backend Updated',
                                preview: 'Connected to $p',
                                icon: Icons.cloud_done_rounded,
                              );
                            }
                          },
                          child: const Text('Save & Apply'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await fb.clearCustomFirebaseConfig();
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                          setState(() {});
                          if (mounted) {
                            ClipboardSyncManager.showSamsungPillToast(
                              context,
                              title: 'Reset to Template',
                              preview: 'Default template restored',
                              icon: Icons.restore_rounded,
                            );
                          }
                        },
                        child: const Text('Reset', style: TextStyle(fontSize: 12)),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.help_outline_rounded, size: 16),
                        label: const Text('3-Min Setup Guide',
                            style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const LegalAndFaqScreen(initialTabIndex: 4),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
                                  'WiFi Sync',
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

              // Bring-Your-Own-Firebase Cloud Configuration
              _sectionLabel(theme, 'Cloud Backend (Bring Your Own Firebase)'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECE8F8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.cloud_outlined,
                            size: 20, color: Color(0xFF5D5094)),
                      ),
                      title: const Text(
                        'Firebase Cloud Project',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Project: ${FirebaseService().activeProjectId}\nStatus: ${FirebaseService().hasCustomConfig ? "Custom Cloud (\$0 Cost)" : "Default / Template"}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      isThreeLine: true,
                      trailing: FilledButton.tonal(
                        onPressed: _showFirebaseConfigDialog,
                        child: const Text('Configure',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      leading: const Icon(Icons.help_outline_rounded, size: 20),
                      title: const Text(
                        'Free Firebase Setup Guide',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text(
                        'Step-by-step 3-minute tutorial with 100% free tier',
                        style: TextStyle(fontSize: 11.5),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const LegalAndFaqScreen(initialTabIndex: 4),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Legal, Regulations & Support
              _sectionLabel(theme, 'Help, Legal & Compliance (GDPR / CCPA)'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      leading: const Icon(Icons.quiz_outlined, size: 20),
                      title: const Text(
                        'Frequently Asked Questions (FAQ)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text(
                        'Security, battery optimization, and sync architecture',
                        style: TextStyle(fontSize: 11.5),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const LegalAndFaqScreen(initialTabIndex: 0),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      leading: const Icon(Icons.privacy_tip_outlined, size: 20),
                      title: const Text(
                        'Privacy Policy',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text(
                        'Zero-tracker disclosure, encryption in transit, data rights',
                        style: TextStyle(fontSize: 11.5),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const LegalAndFaqScreen(initialTabIndex: 1),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      leading: const Icon(Icons.gavel_rounded, size: 20),
                      title: const Text(
                        'Terms of Service & EULA',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text(
                        'MIT License, liability disclaimer, sensitive text notices',
                        style: TextStyle(fontSize: 11.5),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const LegalAndFaqScreen(initialTabIndex: 2),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      leading: const Icon(Icons.support_agent_rounded, size: 20),
                      title: const Text(
                        'Contact Developer & Support',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text(
                        'huraira.eqeel@gmail.com · GitHub issues',
                        style: TextStyle(fontSize: 11.5),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const LegalAndFaqScreen(initialTabIndex: 3),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Data Management & GDPR Right to Erasure
              _sectionLabel(theme, 'Data Management & Privacy Rights'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      leading: Icon(
                        Icons.delete_sweep_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      title: const Text(
                        'Clear Cloud Clipboard History',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text(
                        'Wipe all synchronized clipboard events from Firebase',
                        style: TextStyle(fontSize: 11.5),
                      ),
                      trailing: TextButton(
                        onPressed: _handleClearCloudClipboard,
                        child: const Text('Clear', style: TextStyle(fontSize: 12.5)),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 2),
                      leading: Icon(
                        Icons.person_remove_rounded,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        'Delete Account & Cloud Data',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      subtitle: const Text(
                        'GDPR Article 17: Right to Erasure (destroys account and all records)',
                        style: TextStyle(fontSize: 11.5),
                      ),
                      trailing: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        onPressed: _handleDeleteAccountAndData,
                        child: const Text('Delete', style: TextStyle(fontSize: 12.5)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
