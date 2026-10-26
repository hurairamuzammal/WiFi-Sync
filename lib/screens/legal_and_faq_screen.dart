import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/brand_logo_icon.dart';
import 'developer_screen.dart';

/// Screen presenting international legal documents, GDPR/CCPA disclosures,
/// comprehensive FAQ, support contact information, and free Firebase setup instructions.
class LegalAndFaqScreen extends StatefulWidget {
  final int initialTabIndex;

  const LegalAndFaqScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<LegalAndFaqScreen> createState() => _LegalAndFaqScreenState();
}

class _LegalAndFaqScreenState extends State<LegalAndFaqScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 4),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (!kIsWeb && Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      } else if (!kIsWeb && Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url]);
      } else if (!kIsWeb && Platform.isMacOS) {
        await Process.run('open', [url]);
      }
    } catch (_) {}

    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link copied to clipboard: $url'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            BrandLogoIcon(size: 26),
            SizedBox(width: 10),
            Text(
              'Help & Legal',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'FAQ', icon: Icon(Icons.help_outline_rounded, size: 19)),
            Tab(text: 'Privacy Policy', icon: Icon(Icons.privacy_tip_outlined, size: 19)),
            Tab(text: 'Terms of Service', icon: Icon(Icons.gavel_rounded, size: 19)),
            Tab(text: 'Contact & Support', icon: Icon(Icons.support_agent_rounded, size: 19)),
            Tab(text: 'Free Firebase Guide', icon: Icon(Icons.cloud_outlined, size: 19)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFaqTab(theme),
          _buildPrivacyTab(theme),
          _buildTermsTab(theme),
          _buildContactTab(theme),
          _buildFirebaseGuideTab(theme),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: FAQ
  // ---------------------------------------------------------------------------
  Widget _buildFaqTab(ThemeData theme) {
    final faqs = [
      {
        'q': 'What is ClipSync?',
        'a': 'ClipSync is a cross-platform, private clipboard synchronization utility for Android, Linux, and Windows. It allows text copied on one device to appear immediately on your other connected devices.'
      },
      {
        'q': 'Is my clipboard data private and secure?',
        'a': 'Yes, completely. ClipSync connects exclusively to your own private Firebase Realtime Database project. No third-party servers, developer servers, or advertising networks ever intercept, read, monetize, or store your clipboard content. All communication is encrypted in transit using TLS 1.3.'
      },
      {
        'q': 'Why do I connect my own Firebase project?',
        'a': 'Connecting your own free Firebase project gives you 100% data sovereignty and prevents cloud hosting bills for anyone. You retain total ownership of your database, security rules, and user accounts.'
      },
      {
        'q': 'Does Firebase cost anything to use?',
        'a': 'No. Firebase provides a generous Spark Free Tier that includes 1 GB of Realtime Database storage, 10 GB/month of transfer, and 100 simultaneous connections. For personal clipboard syncing across your phone and laptop, usage typically consumes less than 1% of the free tier allowance. No credit card is required.'
      },
      {
        'q': 'How do I pause syncing when copying sensitive passwords?',
        'a': 'You can turn off the "Clipboard Sync" switch located directly at the top of the Dashboard or in Settings. While turned off, ClipSync completely stops watching your clipboard and suspends the background service.'
      },
      {
        'q': 'How does Android background syncing work on Samsung One UI?',
        'a': 'Android 10+ restricts background apps from reading the clipboard. ClipSync uses an Accessibility Service copy detector to capture copy events, along with an ongoing notification offering a quick "Send to Laptop" action.'
      },
      {
        'q': 'How do I delete all my stored clipboard history or my account?',
        'a': 'You can delete all stored cloud clipboard history at any time from Settings > Account & Data > Clear Cloud Clipboard History. You can also permanently delete your account and all associated data with one click.'
      },
      {
        'q': 'Which platforms are supported?',
        'a': 'ClipSync officially supports Android (10+), Linux (x86_64 desktop with GNOME, KDE, or XFCE), and Windows (10/11 x86_64). macOS, iOS, and Web builds are also supported.'
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: faqs.length,
      itemBuilder: (context, i) {
        final item = faqs[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            title: Text(
              item['q']!,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item['a']!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: PRIVACY POLICY
  // ---------------------------------------------------------------------------
  Widget _buildPrivacyTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerChip(theme, 'GDPR & CCPA Compliant'),
          const SizedBox(height: 10),
          const Text(
            'Privacy Policy',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Last updated: October 2026 · Effective globally',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          _policySection(
            '1. Overview & Data Ownership',
            'ClipSync is built on a bring-your-own-cloud architecture. All data transmitted through ClipSync resides solely in the user\'s private Firebase project or local device storage. The developers of ClipSync have zero access to your database, your authentication tokens, or your clipboard content.',
          ),
          _policySection(
            '2. Data We Process',
            '• Clipboard Text: Text content explicitly copied by the user for synchronization across paired devices.\n'
            '• Device Metadata: Device hostname, platform name (e.g. Android, Linux), and online presence heartbeats.\n'
            '• Authentication Data: Email address and encrypted password hashes managed directly by Firebase Authentication.',
          ),
          _policySection(
            '3. Zero Third-Party Tracking & Zero Monetization',
            'ClipSync contains NO advertising SDKs, NO analytics tracking, NO fingerprinting libraries, and NO data brokering. Your data is never sold, leased, or shared with third parties.',
          ),
          _policySection(
            '4. Security & Encryption in Transit',
            'All network communication is strictly encrypted using TLS 1.3 / HTTPS and secure WebSockets. Local security tokens are stored using platform-native secure storage or SharedPreferences.',
          ),
          _policySection(
            '5. Your Rights (GDPR & CCPA)',
            'Under the General Data Protection Regulation (GDPR) Articles 15-22 and California Consumer Privacy Act (CCPA):\n'
            '• Right to Access: You can view all synchronized devices and history in real time.\n'
            '• Right to Erasure: You may clear cloud clipboard history or delete your entire account and associated data directly within the app.\n'
            '• Right to Opt-Out: You can pause or terminate clipboard syncing at any moment via the master toggle switch.',
          ),
          _policySection(
            '6. Children\'s Privacy (COPPA)',
            'ClipSync is a developer and productivity tool not directed toward children under 13. We do not knowingly collect personal information from children.',
          ),
          _policySection(
            '7. Contact Data Protection Officer',
            'If you have questions regarding privacy compliance or data protection, contact Muhammad Abu Huraira at huraira.eqeel@gmail.com.',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: TERMS OF SERVICE
  // ---------------------------------------------------------------------------
  Widget _buildTermsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerChip(theme, 'Open Source & MIT License'),
          const SizedBox(height: 10),
          const Text(
            'Terms of Service & EULA',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Effective upon downloading or launching ClipSync',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          _policySection(
            '1. License Grant',
            'ClipSync is distributed under the MIT License. You are granted permission to use, study, modify, and distribute the software for personal or commercial purposes, subject to preserving copyright notices.',
          ),
          _policySection(
            '2. Disclaimer of Warranties ("AS IS")',
            'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT.',
          ),
          _policySection(
            '3. Limitation of Liability',
            'IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM OR IN CONNECTION WITH THE SOFTWARE OR THE USE OF THE SOFTWARE.',
          ),
          _policySection(
            '4. User Responsibility for Sensitive Data',
            'Clipboard text may inadvertently contain sensitive items such as passwords, multi-factor codes, API keys, or financial credentials. Users are strongly advised to pause ClipSync or use the master switch when manipulating high-security credentials.',
          ),
          _policySection(
            '5. Third-Party Cloud Services',
            'Users provide their own Firebase or cloud backend. Any terms, rate limits, or usage charges incurred from Google Cloud / Firebase are solely the user\'s responsibility.',
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: CONTACT & SUPPORT
  // ---------------------------------------------------------------------------
  Widget _buildContactTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerChip(theme, 'Direct Developer Support'),
          const SizedBox(height: 10),
          const Text(
            'Contact & Feedback',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Reach out for questions, feature requests, or bug reports.',
            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.person_rounded, color: theme.colorScheme.primary),
                    ),
                    title: const Text(
                      DeveloperScreen.developerName,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Lead Developer & Maintainer'),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Icon(Icons.email_outlined, color: theme.colorScheme.secondary),
                    ),
                    title: const Text('Email Support'),
                    subtitle: const Text('huraira.eqeel@gmail.com'),
                    trailing: TextButton(
                      onPressed: () => _launchUrl('mailto:huraira.eqeel@gmail.com?subject=ClipSync%20Inquiry'),
                      child: const Text('Compose'),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.tertiaryContainer,
                      child: Icon(Icons.code_rounded, color: theme.colorScheme.tertiary),
                    ),
                    title: const Text('GitHub Issues & Repository'),
                    subtitle: const Text('github.com/hurairamuzammal/world_of_iot'),
                    trailing: TextButton(
                      onPressed: () => _launchUrl('https://github.com/hurairamuzammal/world_of_iot/issues'),
                      child: const Text('Open'),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFECE8F8),
                      child: const Icon(Icons.location_on_outlined, color: Color(0xFF5D5094)),
                    ),
                    title: const Text('Location'),
                    subtitle: const Text('Lahore, Punjab, Pakistan'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.volunteer_activism_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'ClipSync is 100% free software. If you enjoy it or have suggestions for new features, star the repository on GitHub!',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 5: FREE FIREBASE GUIDE
  // ---------------------------------------------------------------------------
  Widget _buildFirebaseGuideTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerChip(theme, '100% Free · No Credit Card Required'),
          const SizedBox(height: 10),
          const Text(
            'Connect Your Free Firebase',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Follow this 3-minute guide to configure your own free cloud backend.',
            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          _guideStep(
            theme,
            step: 1,
            title: 'Open Firebase Console',
            body: 'Navigate to console.firebase.google.com and sign in with any Google account. Click "Add project" and name it (e.g. "my-clipsync").',
            buttonLabel: 'Copy Link',
            buttonAction: () => _launchUrl('https://console.firebase.google.com'),
          ),
          _guideStep(
            theme,
            step: 2,
            title: 'Enable Authentication',
            body: 'Go to Build > Authentication > Sign-in method. Enable "Email/Password". (Optional: Also enable "Google" if you wish to use one-tap Google Sign-In).',
          ),
          _guideStep(
            theme,
            step: 3,
            title: 'Create Realtime Database',
            body: 'Go to Build > Realtime Database > Create Database. Choose your region (e.g. us-central1) and start in Test Mode or paste database.rules.json from the repo.',
          ),
          _guideStep(
            theme,
            step: 4,
            title: 'Copy Project ID & Web API Key',
            body: 'Click the Gear icon > Project settings > General. Copy your "Project ID" and "Web API Key". Your Database URL is https://<project-id>-default-rtdb.firebaseio.com.',
          ),
          _guideStep(
            theme,
            step: 5,
            title: 'Paste into ClipSync Settings',
            body: 'In ClipSync, go to Settings > Cloud & Firebase > Configure Firebase Project. Paste your keys and click "Save & Apply". You are now syncing on your own private cloud!',
          ),
        ],
      ),
    );
  }

  Widget _headerChip(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _policySection(String heading, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(fontSize: 13, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _guideStep(
    ThemeData theme, {
    required int step,
    required String title,
    required String body,
    String? buttonLabel,
    VoidCallback? buttonAction,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    '$step',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (buttonLabel != null && buttonAction != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: buttonAction,
                  child: Text(buttonLabel, style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
