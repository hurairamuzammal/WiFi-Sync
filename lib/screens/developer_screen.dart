import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/clipboard_sync_manager.dart';
import '../widgets/brand_logo_icon.dart';

class DeveloperScreen extends StatelessWidget {
  static const String appVersion = '2.1.0';
  static const String appBuild = '210';
  static const String developerName = 'Muhammad Abu Huraira';
  static const String developerEmail = 'huraira.eqeel@gmail.com';

  const DeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Minimal Pastel Brand Header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF262235)
                      : const Color(0xFFEFECFA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF38334E)
                        : const Color(0xFFE0DAF2),
                  ),
                ),
                child: Column(
                  children: [
                    const BrandLogoIcon(size: 72),
                    const SizedBox(height: 14),
                    Text(
                      'ClipSync',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Minimal Cross-Device Clipboard & Remote Actions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF233930)
                            : const Color(0xFFDDF2E8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Version $appVersion ($appBuild)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFA6E1C8)
                              : const Color(0xFF2B6349),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Minimal Developer Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'MH',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  developerName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Creator & Developer',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _PastelTag('Flutter', Color(0xFFECE8F8), Color(0xFF463E66)),
                          _PastelTag('Linux Sync', Color(0xFFE3F4EC), Color(0xFF275B43)),
                          _PastelTag('Firebase RTDB', Color(0xFFFBF0E2), Color(0xFF7A5628)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Clipboard.setData(
                              const ClipboardData(text: developerEmail));
                          ClipboardSyncManager.showSamsungPillToast(
                            context,
                            title: 'Email copied',
                            preview: developerEmail,
                            icon: Icons.email_outlined,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF292636)
                                : const Color(0xFFF8F7FC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.mail_outline_rounded,
                                size: 17,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  developerEmail,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.copy_rounded,
                                size: 15,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
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
      ),
    );
  }
}

class _PastelTag extends StatelessWidget {
  final String label;
  final Color lightBg;
  final Color lightFg;

  const _PastelTag(this.label, this.lightBg, this.lightFg);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2A3C) : lightBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFD5CEF2) : lightFg,
        ),
      ),
    );
  }
}
