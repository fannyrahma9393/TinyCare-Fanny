import 'package:flutter_test/flutter_test.dart';
import 'package:tinycare_mobile/services/fcm_service.dart';

void main() {
  group('FcmNotification.fromData', () {
    test('parses backend child_information payload', () {
      final n = FcmNotification.fromData({
        'link': '/parent/information',
        'type': 'child_information',
        'child_id': '7',
        'information_id': '42',
      }, title: 'Info Baru', body: 'Update tentang anak Anda.');

      expect(n.title, 'Info Baru');
      expect(n.body, 'Update tentang anak Anda.');
      expect(n.link, '/parent/information');
      expect(n.type, 'child_information');
      expect(n.childId, 7);
      expect(n.informationId, 42);
    });

    test('parses with defaults when fields are absent', () {
      final n = FcmNotification.fromData(<String, dynamic>{});
      expect(n.title, 'TinyCare');
      expect(n.body, '');
      expect(n.link, isNull);
      expect(n.type, isNull);
      expect(n.childId, isNull);
      expect(n.informationId, isNull);
    });

    test('ignores non-numeric child_id', () {
      final n = FcmNotification.fromData({
        'child_id': '',
        'information_id': 'abc',
      });
      expect(n.childId, isNull);
      expect(n.informationId, isNull);
    });
  });

  group('FcmNotification.resolveRoute', () {
    test('daily_story -> /daily-stories', () {
      final n = FcmNotification.fromData({'type': 'daily_story'});
      expect(n.resolveRoute(), '/daily-stories');
    });

    test('development -> /development', () {
      final n = FcmNotification.fromData({'type': 'development'});
      expect(n.resolveRoute(), '/development');
    });

    test('child_information -> /information', () {
      final n = FcmNotification.fromData({'type': 'child_information'});
      expect(n.resolveRoute(), '/information');
    });

    test('unknown type -> /dashboard', () {
      final n = FcmNotification.fromData({'type': 'whatever'});
      expect(n.resolveRoute(), '/dashboard');
    });

    test('backend web link /parent/development maps to /development', () {
      final n = FcmNotification.fromData({
        'link': '/parent/development',
        'type': 'development',
      });
      expect(n.resolveRoute(), '/development');
    });

    test('backend web daily-story link with child maps to /daily-stories', () {
      final n = FcmNotification.fromData({
        'link': '/parent/children/5/daily-stories',
        'type': 'daily_story',
      });
      expect(n.resolveRoute(), '/daily-stories');
    });

    test('unknown link falls back to type mapping', () {
      final n = FcmNotification.fromData({
        'link': '/some/other/page',
        'type': 'development',
      });
      expect(n.resolveRoute(), '/development');
    });
  });
}