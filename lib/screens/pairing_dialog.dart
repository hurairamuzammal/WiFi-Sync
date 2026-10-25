import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';

class PairingDialog extends StatefulWidget {
  const PairingDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => const PairingDialog(),
    );
  }

  @override
  State<PairingDialog> createState() => _PairingDialogState();
}

class _PairingDialogState extends State<PairingDialog> {
  String? _pairingCode;
  bool _isLoading = false;
  bool _isRegistering = false;
  String? _error;
  final TextEditingController _nameController =
      TextEditingController(text: 'Linux ThinkPad');

  @override
  void initState() {
    super.initState();
    _generateCode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _generateCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final code = await ApiService().requestPairingCode();
      if (mounted) {
        setState(() {
          _pairingCode = code;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _quickRegisterLinuxDevice() async {
    final name = _nameController.text.trim().isEmpty
        ? 'Linux ThinkPad'
        : _nameController.text.trim();
    setState(() {
      _isRegistering = true;
      _error = null;
    });
    try {
      final dev = await ApiService().registerDevice(
        displayName: name,
        platform: 'linux',
      );
      await ApiService().updateDevice(dev.id, clipboardSyncEnabled: true);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseService().currentUserId ?? ApiService().currentUserId ?? '<UID>';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.link_rounded,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Pair New Device')),
        ],
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Connect your Linux desktop agent or register a new device on your Firebase account:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Device Display Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isRegistering ? null : _quickRegisterLinuxDevice,
                  icon: _isRegistering
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.computer_rounded),
                  label: const Text('Register Linux Device Now'),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                )
              else if (_error != null)
                Column(
                  children: [
                    Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                    const SizedBox(height: 10),
                    FilledButton.tonal(
                      onPressed: _generateCode,
                      child: const Text('Try Again'),
                    ),
                  ],
                )
              else if (_pairingCode != null)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _pairingCode!,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 6,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded),
                            tooltip: 'Copy Code',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _pairingCode!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pairing code copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Linux Agent Command:\n.venv/bin/python3 agent/agent.py --user-id $uid --device-id linux-thinkpad',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Close'),
        ),
        if (_pairingCode != null)
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Done'),
          ),
      ],
    );
  }
}
