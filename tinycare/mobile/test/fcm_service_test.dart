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

    test('parses announcement_id from backend payload', () {
      final n = FcmNotification.fromData({
        'link': '/announcements',
        'type': 'announcement',
        'announcement_id': '42',
      }, title: 'Pengumuman Baru', body: 'Isi pengumuman.');

      expect(n.title, 'Pengumuman Baru');
      expect(n.body, 'Isi pengumuman.');
      expect(n.type, 'announcement');
      expect(n.announcementId, 42);
    });

    test('announcement without id routes to the announcements list', () {
      final n = FcmNotification.fromData({'type': 'announcement'});
      expect(n.announcementId, isNull);
      expect(n.resolveRoute(), '/announcements');
    });

    test('parses invoice_created payload with invoice_id', () {
      final n = FcmNotification.fromData({
        'link': '/invoices',
        'type': 'invoice_created',
        'invoice_id': '123',
      }, title: 'Tagihan Baru', body: 'Tagihan baru untuk Budi.');

      expect(n.type, 'invoice_created');
      expect(n.invoiceId, 123);
      expect(n.canOpenInvoiceDetail, isTrue);
      expect(n.resolveRoute(), '/invoices');
    });

    test('parses payment_submitted payload for admins', () {
      final n = FcmNotification.fromData({
        'link': '/payments',
        'type': 'payment_submitted',
        'payment_id': '55',
        'invoice_id': '123',
      }, title: 'Pembayaran Baru', body: 'Menunggu verifikasi.');

      expect(n.paymentId, 55);
      expect(n.invoiceId, 123);
      expect(n.resolveRoute(), '/payments');
    });

    test('parses payment_verified payload', () {
      final n = FcmNotification.fromData({
        'link': '/invoices',
        'type': 'payment_verified',
        'payment_id': '55',
        'invoice_id': '123',
      }, title: 'Pembayaran Diverifikasi', body: 'Tagihan lunas.');

      expect(n.type, 'payment_verified');
      expect(n.paymentId, 55);
      expect(n.invoiceId, 123);
      expect(n.canOpenInvoiceDetail, isTrue);
    });

    test('parses payment_rejected payload', () {
      final n = FcmNotification.fromData({
        'link': '/invoices',
        'type': 'payment_rejected',
        'payment_id': '55',
        'invoice_id': '123',
      }, title: 'Pembayaran Ditolak', body: 'Alasan: saldo kurang.');

      expect(n.type, 'payment_rejected');
      expect(n.paymentId, 55);
      expect(n.invoiceId, 123);
      expect(n.canOpenInvoiceDetail, isTrue);
    });

    test('parses feedback_created payload for admins', () {
      final n = FcmNotification.fromData({
        'link': '/feedback',
        'type': 'feedback_created',
        'feedback_id': '9',
      }, title: 'Feedback Baru', body: 'Parent A mengirim feedback.');

      expect(n.feedbackId, 9);
      expect(n.resolveRoute(), '/feedback');
    });

    test('parses feedback_replied payload for parents', () {
      final n = FcmNotification.fromData({
        'link': '/feedback',
        'type': 'feedback_replied',
        'feedback_id': '9',
      }, title: 'Feedback Dibalas', body: 'Admin menjawab feedback Anda.');

      expect(n.type, 'feedback_replied');
      expect(n.feedbackId, 9);
      expect(n.resolveRoute(), '/feedback');
    });

    test('payment_submitted admin link maps to /payments', () {
      final n = FcmNotification.fromData({
        'link': '/admin/payments',
        'type': 'payment_submitted',
      });
      expect(n.resolveRoute(), '/payments');
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

    test('invoice_created -> /invoices', () {
      final n = FcmNotification.fromData({'type': 'invoice_created'});
      expect(n.resolveRoute(), '/invoices');
    });

    test('payment_submitted -> /payments', () {
      final n = FcmNotification.fromData({'type': 'payment_submitted'});
      expect(n.resolveRoute(), '/payments');
    });

    test('payment_verified -> /invoices', () {
      final n = FcmNotification.fromData({'type': 'payment_verified'});
      expect(n.resolveRoute(), '/invoices');
    });

    test('payment_rejected -> /invoices', () {
      final n = FcmNotification.fromData({'type': 'payment_rejected'});
      expect(n.resolveRoute(), '/invoices');
    });

    test('feedback_created -> /feedback', () {
      final n = FcmNotification.fromData({'type': 'feedback_created'});
      expect(n.resolveRoute(), '/feedback');
    });

    test('feedback_replied -> /feedback', () {
      final n = FcmNotification.fromData({'type': 'feedback_replied'});
      expect(n.resolveRoute(), '/feedback');
    });
  });
}