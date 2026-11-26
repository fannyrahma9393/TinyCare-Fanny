import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinycare_mobile/services/cached_resource.dart';
import 'package:tinycare_mobile/services/offline_cache_service.dart';
import 'package:tinycare_mobile/utils/api_error.dart';

/// Builds a transport failure (no HTTP response), like a device with no data.
DioException _transportError() => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionError,
      error: 'Connection refused',
    );

/// Builds a 5xx answer: the API answered, but the server is unusable.
DioException _serverError([int status = 500]) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(requestOptions: RequestOptions(path: '/x'), statusCode: status),
    );

/// Builds a 4xx answer, which always proves the API is reachable.
DioException _clientError(int status, {String? message}) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: status,
        data: {'message': message ?? 'Ditolak'},
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OfflineCacheService cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cache = OfflineCacheService.instance;
    await cache.clearAll();
    await cache.unbindUser();
  });

  group('OfflineCacheService user isolation', () {
    test('reads nothing while signed out', () async {
      expect(cache.hasScope, isFalse);
      expect(await cache.read(CacheKeysStub.children), isNull);
      expect(await cache.write(CacheKeysStub.children, [1]), isFalse);
    });

    test('entry written as parent A is invisible to parent B', () async {
      await cache.bindUser(101);
      await cache.write(CacheKeysStub.children, [
        {'id': 1, 'name': 'Anak A'}
      ]);

      await cache.bindUser(202);
      expect(cache.userId, '202');
      expect(await cache.read(CacheKeysStub.children), isNull);
    });

    test('parent B cannot overwrite parent A entry by writing the same key',
        () async {
      await cache.bindUser(101);
      await cache.write(CacheKeysStub.children, [
        {'id': 1, 'name': 'Anak A'}
      ]);

      await cache.bindUser(202);
      await cache.write(CacheKeysStub.children, [
        {'id': 2, 'name': 'Anak B'}
      ]);

      await cache.bindUser(101);
      final entry = await cache.read(CacheKeysStub.children);
      expect((entry!.data as List).first['name'], 'Anak A');

      await cache.bindUser(202);
      final other = await cache.read(CacheKeysStub.children);
      expect((other!.data as List).first['name'], 'Anak B');
    });

    test('logout clears the signed-in user cache only', () async {
      await cache.bindUser(101);
      await cache.write(CacheKeysStub.children, [
        {'id': 1}
      ]);
      await cache.bindUser(202);
      await cache.write(CacheKeysStub.children, [
        {'id': 2}
      ]);

      await cache.bindUser(101);
      await cache.clearCurrentUser();

      expect(await cache.read(CacheKeysStub.children), isNull);

      await cache.bindUser(202);
      expect(await cache.read(CacheKeysStub.children), isNotNull);
    });

    test('unbindUser stops all access immediately', () async {
      await cache.bindUser(101);
      await cache.write(CacheKeysStub.children, [
        {'id': 1}
      ]);
      await cache.unbindUser();

      expect(cache.hasScope, isFalse);
      expect(await cache.read(CacheKeysStub.children), isNull);
    });

    test('child-scoped keys stay separate per child', () async {
      await cache.bindUser(101);
      await cache.write('parent.child.1.activities', [
        {'id': 1, 'child_id': 1}
      ]);
      await cache.write('parent.child.2.activities', [
        {'id': 2, 'child_id': 2}
      ]);

      final first = await cache.read('parent.child.1.activities');
      final second = await cache.read('parent.child.2.activities');
      expect((first!.data as List).first['child_id'], 1);
      expect((second!.data as List).first['child_id'], 2);
    });
  });

  group('OfflineCacheService payload safety', () {
    setUp(() => cache.bindUser(101));

    test('write stores the payload with a timestamp', () async {
      final when = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      expect(await cache.write('k', [
        {'id': 1}
      ], now: when), isTrue);

      final entry = await cache.read('k');
      expect(entry, isNotNull);
      expect(entry!.updatedAt, when);
      expect(entry.key, 'k');
    });

    test('credential-like fields are stripped, recursively', () async {
      await cache.write('k', {
        'id': 1,
        'token': 'super-secret',
        'password': 'hunter2',
        'api_secret': 'nope',
        'profile': {
          'name': 'Budi',
          'access_token': 'leak-me',
        },
        'children': [
          {'name': 'Ani', 'password_confirmation': 'leak'},
        ],
      });

      final stored = jsonEncode((await cache.read('k'))!.data);
      expect(stored, isNot(contains('super-secret')));
      expect(stored, isNot(contains('hunter2')));
      expect(stored, isNot(contains('leak-me')));
      expect(stored, isNot(contains('nope')));
      expect(stored, contains('Budi'));
      expect(stored, contains('Ani'));
    });

    test('oversized payloads are skipped instead of stored', () async {
      final huge = List.generate(20000, (i) => {'id': i, 'pad': 'x' * 40});
      expect(await cache.write('big', huge), isFalse);
      expect(await cache.read('big'), isNull);
    });

    test('null payloads are not written', () async {
      expect(await cache.write('k', null), isFalse);
      expect(await cache.read('k'), isNull);
    });

    test('lastUpdated reports the newest successful write', () async {
      final first = DateTime.fromMillisecondsSinceEpoch(1700000000000);
      final second = DateTime.fromMillisecondsSinceEpoch(1700000600000);

      await cache.write('k', [
        {'id': 1}
      ], now: first);
      await cache.write('k', [
        {'id': 2}
      ], now: second);

      expect(await cache.lastUpdated('k'), second);
    });

    test('corrupt stored JSON is ignored instead of crashing', () async {
      SharedPreferences.setMockInitialValues({
        'tc_cache_v1_data_101::k': 'not-json{',
      });
      await cache.bindUser(101);
      expect(await cache.read('k'), isNull);
    });
  });

  group('CachedResource cache-first load', () {
    setUp(() async {
      await cache.bindUser(101);
    });

    test('successful fetch renders online and seeds the cache', () async {
      final resource = CachedResource<List<dynamic>>(onChanged: () {});

      await resource.load(
        cacheKey: 'children',
        fetch: () async => [
          {'id': 1, 'name': 'Ani'}
        ],
      );

      expect(resource.status, ResourceStatus.online);
      expect(resource.isOffline, isFalse);
      expect(resource.hasError, isFalse);
      expect(resource.isFromCache, isFalse);
      expect(resource.data!.length, 1);
      expect(resource.lastUpdated, isNotNull);

      final entry = await cache.read('children');
      expect(entry, isNotNull);
    });

    test('cached payload renders before the API answers', () async {
      await cache.write('children', [
        {'id': 1, 'name': 'Ani'}
      ]);

      var notifiedWhilePending = false;
      late final CachedResource<List<dynamic>> resource;
      resource = CachedResource<List<dynamic>>(onChanged: () {
        if (resource.isRefreshing) notifiedWhilePending = true;
      });

      final future = resource.load(
        cacheKey: 'children',
        fetch: () async {
          // The cached copy must already be on screen at this point.
          expect(resource.hasData, isTrue);
          expect(resource.isFromCache, isTrue);
          expect(resource.isLoading, isFalse);
          return <dynamic>[];
        },
      );
      await future;

      expect(notifiedWhilePending, isTrue);
      expect(resource.status, ResourceStatus.empty);
      expect(resource.isFromCache, isFalse);
    });

    test('empty API response reports empty, not offline', () async {
      final resource = CachedResource<List<dynamic>>(onChanged: () {});
      await resource.load(cacheKey: 'k', fetch: () async => []);

      expect(resource.status, ResourceStatus.empty);
      expect(resource.isEmpty, isTrue);
      expect(resource.isOffline, isFalse);
      expect(resource.hasError, isFalse);
    });

    test('custom isEmptyData marks an empty envelope as empty', () async {
      final resource = CachedResource<Map<String, dynamic>>(
        onChanged: () {},
        isEmptyData: (data) => data.isEmpty || data['data'] == null,
      );
      await resource.load(
        cacheKey: 'profile',
        fetch: () async => <String, dynamic>{'success': true, 'data': null},
      );

      expect(resource.status, ResourceStatus.empty);
    });
  });

  group('CachedResource offline fallback', () {
    setUp(() => cache.bindUser(101));

    test('no cache + unreachable API reports error, not empty', () async {
      final resource = CachedResource<List<dynamic>>(onChanged: () {});

      await resource.load(
        cacheKey: 'k',
        fetch: () async => throw _transportError(),
        errorKey: 'Gagal memuat data.',
      );

      expect(resource.hasData, isFalse);
      expect(resource.status, ResourceStatus.error);
      expect(resource.error, 'Gagal memuat data.');
      expect(resource.isOffline, isFalse);
    });

    test('cache + unreachable API keeps showing cached data', () async {
      await cache.write('k', [
        {'id': 1, 'name': 'Ani'}
      ]);

      final resource = CachedResource<List<dynamic>>(onChanged: () {});
      await resource.load(
        cacheKey: 'k',
        fetch: () async => throw _transportError(),
      );

      expect(resource.status, ResourceStatus.offline);
      expect(resource.isOffline, isTrue);
      expect(resource.hasError, isFalse);
      expect(resource.isFromCache, isTrue);
      expect((resource.data!).first['name'], 'Ani');
    });

    test('cache + 5xx is treated as offline too', () async {
      await cache.write('k', [
        {'id': 1}
      ]);

      final resource = CachedResource<List<dynamic>>(onChanged: () {});
      await resource.load(cacheKey: 'k', fetch: () async => throw _serverError());

      expect(resource.isOffline, isTrue);
      expect(resource.hasData, isTrue);
    });

    test('cache is not overwritten by a failed request', () async {
      await cache.write('k', [
        {'id': 1, 'name': 'Ani'}
      ]);

      final resource = CachedResource<List<dynamic>>(onChanged: () {});
      await resource.load(cacheKey: 'k', fetch: () async => throw _transportError());

      final entry = await cache.read('k');
      expect((entry!.data as List).first['name'], 'Ani');
    });

    test('failed request does not bump lastUpdated', () async {
      await cache.write(
        'k',
        [
          {'id': 1}
        ],
        now: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );

      final resource = CachedResource<List<dynamic>>(onChanged: () {});
      await resource.load(cacheKey: 'k', fetch: () async => throw _transportError());

      expect(
        resource.lastUpdated,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
    });
  });

  group('CachedResource 4xx keeps the regular error flow', () {
    setUp(() => cache.bindUser(101));

    test('401 never falls back to cache', () async {
      await cache.write('k', [
        {'id': 1, 'name': 'Ani'}
      ]);

      final resource = CachedResource<List<dynamic>>(onChanged: () {});
      await resource.load(
        cacheKey: 'k',
        fetch: () async => throw _clientError(401, message: 'Unauthenticated.'),
        errorKey: 'Gagal memuat data.',
      );

      expect(resource.isOffline, isFalse);
      expect(resource.status, ResourceStatus.error);
      expect(resource.error, 'Unauthenticated.');
      expect(resource.hasData, isFalse);
      // The cached copy is dropped too, so a later visit cannot resurrect it.
      expect(await cache.read('k'), isNull);
    });

    test('403 is a permission error, not an offline state', () async {
      final resource = CachedResource<List<dynamic>>(onChanged: () {});
      await resource.load(
        cacheKey: 'k',
        fetch: () async => throw _clientError(403),
      );

      expect(resource.isOffline, isFalse);
      expect(resource.status, ResourceStatus.error);
    });

    test('422 uses the API message', () async {
      final resource = CachedResource<List<dynamic>>(onChanged: () {});
      await resource.load(
        cacheKey: 'k',
        fetch: () async => throw _clientError(422, message: 'Data tidak valid.'),
      );

      expect(resource.error, 'Data tidak valid.');
    });
  });

  group('ApiErrorHandler.isReachabilityError', () {
    test('transport and 5xx failures are reachability problems', () {
      expect(ApiErrorHandler.isReachabilityError(_transportError()), isTrue);
      expect(ApiErrorHandler.isReachabilityError(_serverError(500)), isTrue);
      expect(ApiErrorHandler.isReachabilityError(_serverError(503)), isTrue);
    });

    test('any 4xx proves the API is reachable', () {
      for (final status in [400, 401, 403, 404, 409, 422, 429]) {
        expect(
          ApiErrorHandler.isReachabilityError(_clientError(status)),
          isFalse,
          reason: '$status must not be treated as offline',
        );
      }
    });

    test('timeouts are reachability problems', () {
      expect(
        ApiErrorHandler.isReachabilityError(
          DioException(
            requestOptions: RequestOptions(path: '/x'),
            type: DioExceptionType.receiveTimeout,
          ),
        ),
        isTrue,
      );
    });
  });

  group('write failure messaging', () {
    test('offline write says the data was not sent', () {
      final message = ApiErrorHandler.writeFailureMessage(_transportError());
      expect(message, 'Tidak ada koneksi. Data belum dikirim.');
    });

    test('online write failure surfaces the API message', () {
      final message = ApiErrorHandler.writeFailureMessage(
        _clientError(422, message: 'Password lama salah.'),
      );
      expect(message, 'Password lama salah.');
    });
  });
}

/// Local aliases so the test reads the same way as the production call sites.
class CacheKeysStub {
  static const String children = 'parent.children';
}
