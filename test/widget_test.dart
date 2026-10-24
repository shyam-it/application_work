import 'package:flutter_test/flutter_test.dart';
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
}
