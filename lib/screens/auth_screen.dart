import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/clipboard_sync_manager.dart';
import '../widgets/brand_logo_icon.dart';
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

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ApiService().signInWithGoogle();
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

  Future<void> _handleForgotPasswordDialog() async {
    final resetEmailCtrl =
        TextEditingController(text: _loginEmailController.text.trim());

    final emailToReset = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your email address to receive a reset link (Email & Password accounts only).',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined, size: 19),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(resetEmailCtrl.text.trim()),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );

    if (emailToReset == null || emailToReset.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ApiService().sendPasswordResetEmail(emailToReset);
      if (mounted) {
        ClipboardSyncManager.showSamsungPillToast(
          context,
          title: 'Reset link sent',
          preview: emailToReset,
          icon: Icons.mark_email_read_outlined,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              constraints: const BoxConstraints(maxWidth: 400),
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
                            height: 280,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                Form(
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
                                              : _handleForgotPasswordDialog,
                                          child: const Text(
                                            'Forgot password?',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
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
                                    ],
                                  ),
                                ),
                                Form(
                                  key: _registerFormKey,
                                  child: Column(
                                    children: [
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
                                        controller: _registerPasswordController,
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
                                        controller: _registerConfirmController,
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
                                      const Spacer(),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          minimumSize:
                                              const Size.fromHeight(46),
                                        ),
                                        onPressed:
                                            _isLoading ? null : _handleRegister,
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
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Divider(),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              side: BorderSide(
                                color: theme.colorScheme.outlineVariant,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleGoogleSignIn,
                            icon: Icon(
                              Icons.g_mobiledata_rounded,
                              size: 24,
                              color: theme.colorScheme.primary,
                            ),
                            label: const Text('Continue with Google'),
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
