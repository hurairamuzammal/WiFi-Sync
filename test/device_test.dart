import 'package:flutter_test/flutter_test.dart';
import 'package:world_of_iot/models/device.dart';

void main() {
  group('Device Model Unit Tests', () {
    test('Correctly deserializes from backend JSON', () {
      final json = {
        'id': 'dev-1234',
        'user_id': 'usr-5678',
        'display_name': 'Living Room PC',
        'platform': 'linux',
        'agent_version': '1.0.0',
        'created_at': '2026-10-21T10:00:00Z',
        'last_seen_at': '2026-10-21T10:15:00Z',
        'status': 'online',
        'revoked_at': null,
        'clipboard_sync_enabled': 1,
      };

      final device = Device.fromJson(json);

      expect(device.id, 'dev-1234');
      expect(device.displayName, 'Living Room PC');
      expect(device.platform, 'linux');
      expect(device.isOnline, true);
      expect(device.isRevoked, false);
      expect(device.clipboardSyncEnabled, true);
    });

    test('Correctly identifies offline and revoked state', () {
      final json = {
        'id': 'dev-999',
        'user_id': 'usr-5678',
        'display_name': 'Office Laptop',
        'platform': 'windows',
        'status': 'offline',
        'revoked_at': '2026-10-21T09:00:00Z',
        'clipboard_sync_enabled': false,
        'created_at': '2026-10-21T08:00:00Z',
      };

      final device = Device.fromJson(json);

      expect(device.isOnline, false);
      expect(device.isRevoked, true);
      expect(device.clipboardSyncEnabled, false);
    });

    test('copyWith properly preserves unmodified properties', () {
      final original = Device(
        id: '1',
        userId: 'u1',
        displayName: 'Old Name',
        platform: 'linux',
        createdAt: 'now',
        status: 'offline',
        clipboardSyncEnabled: false,
      );

      final updated = original.copyWith(
        displayName: 'New Name',
        status: 'online',
      );

      expect(updated.id, '1');
      expect(updated.displayName, 'New Name');
      expect(updated.status, 'online');
      expect(updated.clipboardSyncEnabled, false);
    });
  });
}
