import 'package:flutter_test/flutter_test.dart';
import 'package:world_of_iot/models/command.dart';

void main() {
  group('DeviceCommand Model Unit Tests', () {
    test('Correctly deserializes from backend JSON', () {
      final json = {
        'id': 'cmd-1',
        'user_id': 'u1',
        'device_id': 'd1',
        'action': 'shutdown',
        'status': 'accepted',
        'created_at': '2026-10-21T10:00:00Z',
        'expires_at': '2026-10-21T10:01:00Z',
        'accepted_at': '2026-10-21T10:00:02Z',
        'finished_at': null,
        'error_code': null,
        'result_summary': null,
      };

      final cmd = DeviceCommand.fromJson(json);

      expect(cmd.id, 'cmd-1');
      expect(cmd.action, 'shutdown');
      expect(cmd.status, 'accepted');
      expect(cmd.acceptedAt, '2026-10-21T10:00:02Z');
    });

    test('Correctly serializes back to JSON', () {
      final cmd = DeviceCommand(
        id: 'cmd-2',
        userId: 'u1',
        deviceId: 'd1',
        action: 'health_check',
        status: 'succeeded',
        createdAt: 'now',
        expiresAt: 'now+60',
        resultSummary: 'Health OK',
      );

      final map = cmd.toJson();

      expect(map['id'], 'cmd-2');
      expect(map['action'], 'health_check');
      expect(map['status'], 'succeeded');
      expect(map['result_summary'], 'Health OK');
    });
  });
}
