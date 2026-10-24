import 'package:flutter_test/flutter_test.dart';
import 'package:work_mart/models/attendance_record.dart';
import 'package:work_mart/models/site.dart';

void main() {
  group('Site model', () {
    test('creates a site from Firestore data with defaults', () {
      final site = Site.fromMap({'name': 'Hari Om'}, 'site-1');
      expect(site.id, 'site-1');
      expect(site.name, 'Hari Om');
      expect(site.isActive, isTrue);
    });

    test('serializes site data without embedding document id', () {
      const site = Site(id: 'site-2', name: 'Heritage', isActive: false);
      expect(site.toMap(), {'name': 'Heritage', 'isActive': false});
    });
  });

  group('Attendance models', () {
    test('serializes multiple site work times', () {
      const record = AttendanceRecord(
        workerId: 'worker-1',
        workerUid: 'auth-uid-1',
        workerName: 'Rahul Patel',
        date: '2026-10-25',
        status: 'Half-day',
        siteWorkTimes: [
          SiteWorkTime(
            siteId: 's1',
            siteName: 'Hari Om',
            startTime: '08:00',
            endTime: '12:00',
          ),
          SiteWorkTime(
            siteId: 's2',
            siteName: 'Heritage',
            startTime: '13:00',
            endTime: '17:00',
          ),
        ],
      );
      final restored = AttendanceRecord.fromMap(record.toMap());
      expect(restored.status, 'Half-day');
      expect(restored.workerUid, 'auth-uid-1');
      expect(restored.siteWorkTimes, hasLength(2));
      expect(restored.siteWorkTimes.last.siteName, 'Heritage');
    });
  });
}
