import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/clipboard_sync_manager.dart';
import '../services/firebase_service.dart';
import '../widgets/brand_logo_icon.dart';
import '../widgets/google_logo_icon.dart';
import 'dashboard_screen.dart';
import 'developer_screen.dart';
import 'legal_and_faq_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmController = TextEditingController();

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService().logIn(
        _loginEmailController.text.trim(),
        _loginPasswordController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    if (_registerPasswordController.text.trim() !=
        _registerConfirmController.text.trim()) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService().signUp(
        _registerEmailController.text.trim(),
        _registerPasswordController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleAuth({required bool isSignUp}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (isSignUp) {
        await ApiService().signUpWithGoogle();
      } else {
        await ApiService().signInWithGoogle();
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Comprehensive Account Recovery & Forget Options Sheet
  Future<void> _showForgetOptionsDialog({String? defaultEmail}) async {
    final emailCtrl = TextEditingController(
      text: (defaultEmail != null && defaultEmail.isNotEmpty)
          ? defaultEmail
          : (_loginEmailController.text.trim().isNotEmpty
              ? _loginEmailController.text.trim()
              : _registerEmailController.text.trim()),
    );
    String? localError;
    bool isSending = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = Theme.of(ctx);
          final isDark = theme.brightness == Brightness.dark;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 18,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1C27) : theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
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
                        color: theme.colorScheme.outlineVariant,
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
                          color: isDark
                              ? const Color(0xFF2E2A40)
                              : const Color(0xFFECE8F8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.lock_reset_rounded,
                          size: 22,
                          color: isDark
                              ? const Color(0xFFC4BCEA)
                              : const Color(0xFF4B3F72),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Recovery & Forget Options',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Reset password or recover sign-in method',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (localError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCEBEC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 16, color: Color(0xFF94383C)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              localError!,
                              style: const TextStyle(
                                color: Color(0xFF94383C),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Account Email',
                      hintText: 'user@example.com',
                      prefixIcon: Icon(Icons.email_outlined, size: 19),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: isSending
                        ? null
                        : () async {
                            final email = emailCtrl.text.trim();
                            if (email.isEmpty || !email.contains('@')) {
                              setModalState(() =>
                                  localError = 'Please enter a valid email address.');
                              return;
                            }
                            setModalState(() {
                              isSending = true;
                              localError = null;
                            });
                            try {
                              await ApiService().sendPasswordResetEmail(email);
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                              }
                              if (mounted) {
                                ClipboardSyncManager.showSamsungPillToast(
                                  context,
                                  title: 'Reset link sent',
                                  preview: email,
                                  icon: Icons.mark_email_read_outlined,
                                );
                              }
                            } catch (e) {
                              setModalState(() {
                                isSending = false;
                                localError = e
                                    .toString()
                                    .replaceAll('Exception: ', '');
                              });
                            }
                          },
                    icon: isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(isSending
                        ? 'Sending reset link...'
                        : 'Send Password Reset Link'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _handleGoogleAuth(isSignUp: false);
                    },
                    icon: const GoogleLogoIcon(size: 18),
                    label: const Text('Used Google Sign-In? Tap here'),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF262335)
                          : const Color(0xFFF4F2FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF37324A)
                            : const Color(0xFFE4DFEE),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 15,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(
                              'Forget / Recovery Note',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Password reset links apply to Email & Password accounts. If you originally registered with Google OAuth, use the Google button above.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFirebaseSetupDialog() {
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
                              'Private, free personal cloud backend (\$0 cost)',
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
                      hintText: 'e.g. my-wifisync-hub',
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
                                        ? 'Connection successful! Database is reachable.'
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
                                title: 'Cloud Connected',
                                preview: p,
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
                        },
                        child: const Text('Reset', style: TextStyle(fontSize: 12)),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.help_outline_rounded, size: 16),
                        label: const Text('3-Min Free Setup Guide',
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

  Widget _dividerWithText(ThemeData theme, String text) {
    return Row(
      children: [
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BrandLogoIcon(size: 72),
                  const SizedBox(height: 16),
                  Text(
                    'WiFi Sync',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cross-Device Remote Actions & Clipboard Sync',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Bring-Your-Own-Firebase Quick Connect Strip
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECE8F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDAD3F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_outlined,
                            size: 18, color: Color(0xFF5D5094)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            FirebaseService().hasCustomConfig
                                ? 'Cloud: ${FirebaseService().activeProjectId}'
                                : 'Bring Your Own Firebase (\$0 Free Tier)',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF342C54),
                            ),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: _showFirebaseSetupDialog,
                          child: const Text('Connect',
                              style: TextStyle(fontSize: 11.5)),
                        ),
                      ],
                    ),
                  ),
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCEBEC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 18, color: Color(0xFF94383C)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFF94383C),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              indicator: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              tabs: const [
                                Tab(height: 36, text: 'Sign In'),
                                Tab(height: 36, text: 'Create Account'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 380,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Tab 0: Sign In
                                SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Form(
                                    key: _loginFormKey,
                                    child: Column(
                                      children: [
                                        TextFormField(
                                          controller: _loginEmailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          decoration: const InputDecoration(
                                            labelText: 'Email',
                                            prefixIcon: Icon(
                                                Icons.email_outlined,
                                                size: 19),
                                          ),
                                          validator: (v) => v == null || v.isEmpty
                                              ? 'Email required'
                                              : null,
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: _loginPasswordController,
                                          obscureText: _obscurePassword,
                                          decoration: InputDecoration(
                                            labelText: 'Password',
                                            prefixIcon: const Icon(
                                                Icons.lock_outline,
                                                size: 19),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                        .visibility_off_outlined,
                                                size: 19,
                                              ),
                                              onPressed: () => setState(() =>
                                                  _obscurePassword =
                                                      !_obscurePassword),
                                            ),
                                          ),
                                          validator: (v) => v == null || v.isEmpty
                                              ? 'Password required'
                                              : null,
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: _isLoading
                                                ? null
                                                : () =>
                                                    _showForgetOptionsDialog(),
                                            child: const Text(
                                              'Forgot password / options?',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            minimumSize:
                                                const Size.fromHeight(46),
                                          ),
                                          onPressed:
                                              _isLoading ? null : _handleLogin,
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 18,
                                                  width: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white),
                                                )
                                              : const Text('Sign In'),
                                        ),
                                        const SizedBox(height: 16),
                                        _dividerWithText(
                                            theme, 'OR CONTINUE WITH'),
                                        const SizedBox(height: 14),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            minimumSize:
                                                const Size.fromHeight(44),
                                            side: BorderSide(
                                              color: theme
                                                  .colorScheme.outlineVariant,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: _isLoading
                                              ? null
                                              : () => _handleGoogleAuth(
                                                  isSignUp: false),
                                          icon: const GoogleLogoIcon(size: 20),
                                          label: const Text(
                                              'Sign in with Google'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Tab 1: Create Account
                                SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Form(
                                    key: _registerFormKey,
                                    child: Column(
                                      children: [
                                        // Prominent Sign up with Google Option
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            minimumSize:
                                                const Size.fromHeight(44),
                                            side: BorderSide(
                                              color: theme
                                                  .colorScheme.outlineVariant,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: _isLoading
                                              ? null
                                              : () => _handleGoogleAuth(
                                                  isSignUp: true),
                                          icon: const GoogleLogoIcon(size: 20),
                                          label: const Text(
                                              'Sign up with Google'),
                                        ),
                                        const SizedBox(height: 14),
                                        _dividerWithText(
                                            theme, 'OR REGISTER WITH EMAIL'),
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller: _registerEmailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          decoration: const InputDecoration(
                                            labelText: 'Email',
                                            prefixIcon: Icon(
                                                Icons.email_outlined,
                                                size: 19),
                                          ),
                                          validator: (v) => v == null || v.isEmpty
                                              ? 'Email required'
                                              : null,
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller:
                                              _registerPasswordController,
                                          obscureText: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Password (min 6 chars)',
                                            prefixIcon: Icon(
                                                Icons.lock_outline,
                                                size: 19),
                                          ),
                                          validator: (v) =>
                                              v != null && v.length >= 6
                                                  ? null
                                                  : 'Minimum 6 characters',
                                        ),
                                        const SizedBox(height: 10),
                                        TextFormField(
                                          controller:
                                              _registerConfirmController,
                                          obscureText: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Confirm Password',
                                            prefixIcon: Icon(
                                                Icons.lock_outline,
                                                size: 19),
                                          ),
                                          validator: (v) => v == null || v.isEmpty
                                              ? 'Confirm password'
                                              : null,
                                        ),
                                        const SizedBox(height: 14),
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            minimumSize:
                                                const Size.fromHeight(46),
                                          ),
                                          onPressed: _isLoading
                                              ? null
                                              : _handleRegister,
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 18,
                                                  width: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white),
                                                )
                                              : const Text('Register Account'),
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: _isLoading
                                                ? null
                                                : () =>
                                                    _showForgetOptionsDialog(),
                                            child: const Text(
                                              'Forgot account or password?',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const DeveloperScreen()),
                      );
                    },
                    child: Text(
                      'v${DeveloperScreen.appVersion} · ${DeveloperScreen.developerName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const LegalAndFaqScreen(initialTabIndex: 1),
                          ),
                        ),
                        child: const Text('Privacy Policy',
                            style: TextStyle(fontSize: 11)),
                      ),
                      const Text('·', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const LegalAndFaqScreen(initialTabIndex: 2),
                          ),
                        ),
                        child:
                            const Text('Terms', style: TextStyle(fontSize: 11)),
                      ),
                      const Text('·', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const LegalAndFaqScreen(initialTabIndex: 0),
                          ),
                        ),
                        child:
                            const Text('FAQ', style: TextStyle(fontSize: 11)),
                      ),
                      const Text('·', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const LegalAndFaqScreen(initialTabIndex: 3),
                          ),
                        ),
                        child: const Text('Support',
                            style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
