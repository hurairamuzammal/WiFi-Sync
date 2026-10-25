import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/clipboard_sync_manager.dart';
import '../widgets/brand_logo_icon.dart';
import '../widgets/google_logo_icon.dart';
import 'dashboard_screen.dart';
import 'developer_screen.dart';

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
                    'World of IT',
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
                  const SizedBox(height: 22),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
