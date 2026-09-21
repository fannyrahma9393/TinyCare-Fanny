import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinycare_mobile/l10n/app_strings.dart';
import 'package:tinycare_mobile/l10n/partials/admin_core.dart';
import 'package:tinycare_mobile/l10n/partials/admin_daily.dart';
import 'package:tinycare_mobile/l10n/partials/admin_finance.dart';
import 'package:tinycare_mobile/l10n/partials/admin_mgmt.dart';
import 'package:tinycare_mobile/l10n/partials/auth.dart';
import 'package:tinycare_mobile/l10n/partials/common.dart';
import 'package:tinycare_mobile/l10n/partials/components.dart';
import 'package:tinycare_mobile/l10n/partials/parent.dart';
import 'package:tinycare_mobile/l10n/partials/scaffolds.dart';
import 'package:tinycare_mobile/l10n/register.dart';

/// Every English catalog partial, keyed by its file name under
/// `lib/l10n/partials/`. Used to cross-check registration and collisions.
const Map<String, Map<String, String>> _partials = {
  'common': commonEn,
  'auth': authEn,
  'admin_core': adminCoreEn,
  'admin_finance': adminFinanceEn,
  'admin_daily': adminDailyEn,
  'admin_mgmt': adminMgmtEn,
  'parent': parentEn,
  'components': componentsEn,
  'scaffolds': scaffoldsEn,
};

void main() {
  registerLocalizations();

  test('every tr() key used in lib/ has an English translation', () {
    final libDir = Directory('lib');
    expect(
      libDir.existsSync(),
      isTrue,
      reason: 'Run the tests from the mobile package root (`flutter test`).',
    );

    final catalog = AppStrings.instance.englishCatalog;
    expect(catalog, isNotEmpty, reason: 'The English catalog is empty.');

    final missing = <String, List<String>>{};
    final used = <String>{};

    for (final file in _dartFiles(libDir)) {
      final path = file.path.replaceAll(r'\', '/');
      // The catalog itself is not a consumer of `tr()`.
      if (path.startsWith('lib/l10n/')) continue;

      final source = file.readAsStringSync();
      final lineStarts = _lineStarts(source);
      for (final hit in _findTrKeys(source, lineStarts)) {
        used.add(hit.key);
        if (!catalog.containsKey(hit.key)) {
          missing.putIfAbsent(hit.key, () => <String>[]).add('$path:${hit.line}');
        }
      }
    }

    // Guard against the scanner silently finding nothing, which would make the
    // assertion below pass for the wrong reason.
    expect(used, isNotEmpty, reason: 'No tr() call sites were found under lib/.');

    final report = (missing.keys.toList()..sort())
        .map((key) => '  "$key"  (${missing[key]!.join(', ')})')
        .join('\n');
    expect(
      missing,
      isEmpty,
      reason: 'These keys are used with tr() but have no English translation.\n'
          'Add them to the matching file in lib/l10n/partials/:\n$report',
    );
  });

  test('registerLocalizations() registers every partial', () {
    final merged = <String, String>{};
    for (final partial in _partials.values) {
      merged.addAll(partial);
    }

    final catalog = AppStrings.instance.englishCatalog;
    final unregistered = merged.keys.toSet().difference(catalog.keys.toSet());
    final unknown = catalog.keys.toSet().difference(merged.keys.toSet());

    expect(
      unregistered,
      isEmpty,
      reason: 'These keys live in a partial that register.dart never adds: '
          '${unregistered.toList()..sort()}',
    );
    expect(
      unknown,
      isEmpty,
      reason: 'register.dart adds keys that no partial defines: '
          '${unknown.toList()..sort()}',
    );
  });

  test('no key is translated differently by two partials', () {
    final owners = <String, String>{};
    final conflicts = <String>[];

    for (final partial in _partials.entries) {
      for (final entry in partial.value.entries) {
        final current = '${partial.key}="${entry.value}"';
        final previous = owners[entry.key];
        if (previous != null && previous != current) {
          conflicts.add('  "${entry.key}": $previous  vs  $current');
        }
        owners[entry.key] = current;
      }
    }

    expect(
      conflicts,
      isEmpty,
      reason: 'The same key resolves to different English text. Keep exactly '
          'one definition:\n${conflicts.join('\n')}',
    );
  });
}

/// A `tr('...')` call site: the key text and the line it is on.
class _TrKey {
  const _TrKey(this.key, this.line);

  final String key;
  final int line;
}

/// Finds every string literal passed as the first argument of `tr(...)`,
/// skipping comments and other string literals.
Iterable<_TrKey> _findTrKeys(String source, List<int> lineStarts) sync* {
  var index = 0;
  while (index < source.length) {
    final char = source[index];

    // Comments may legitimately contain `tr('Simpan')` examples.
    if (char == '/' && index + 1 < source.length) {
      if (source[index + 1] == '/') {
        final end = source.indexOf('\n', index);
        index = end == -1 ? source.length : end + 1;
        continue;
      }
      if (source[index + 1] == '*') {
        final end = source.indexOf('*/', index + 2);
        index = end == -1 ? source.length : end + 2;
        continue;
      }
    }

    // Skip any other string literal (including raw ones) in one step.
    if (char == '"' || char == "'") {
      final literal = _readString(source, index);
      index = literal?.end ?? index + 1;
      continue;
    }

    if (char == 't' &&
        source.startsWith('tr', index) &&
        !_isIdentifier(index > 0 ? source.codeUnitAt(index - 1) : 0) &&
        !_isIdentifier(
            index + 2 < source.length ? source.codeUnitAt(index + 2) : 0)) {
      var cursor = index + 2;
      while (cursor < source.length && _isWhitespace(source[cursor])) {
        cursor++;
      }
      if (cursor < source.length && source[cursor] == '(') {
        cursor++;
        while (cursor < source.length && _isWhitespace(source[cursor])) {
          cursor++;
        }
        if (cursor < source.length &&
            (source[cursor] == "'" || source[cursor] == '"')) {
          final literal = _readString(source, cursor);
          if (literal != null) {
            yield _TrKey(
              _unescape(literal.body),
              _lineNumber(lineStarts, index),
            );
            index = literal.end;
            continue;
          }
        }
      }
    }

    index++;
  }
}

/// Reads the Dart string literal starting at [position] (the opening quote).
///
/// Handles raw strings, escapes, triple quotes and `${...}` interpolation
/// (including nested strings inside the interpolation), so that a literal is
/// always consumed as a whole.
_StringLiteral? _readString(String source, int position) {
  final quoteChar = source[position];
  if (quoteChar != '"' && quoteChar != "'") return null;

  final triple = source.startsWith(quoteChar * 3, position);
  final quote = triple ? quoteChar * 3 : quoteChar;
  final raw = position > 0 &&
      source[position - 1] == 'r' &&
      !_isIdentifier(position > 1 ? source.codeUnitAt(position - 2) : 0);

  var index = position + quote.length;
  while (index < source.length) {
    if (!raw && source[index] == '\\') {
      index += 2;
      continue;
    }

    if (source.startsWith(quote, index)) {
      return _StringLiteral(
        end: index + quote.length,
        body: source.substring(position + quote.length, index),
      );
    }

    if (!raw && source[index] == r'$') {
      if (index + 1 < source.length && source[index + 1] == '{') {
        var depth = 0;
        var cursor = index + 1;
        while (cursor < source.length) {
          final char = source[cursor];
          if (char == '"' || char == "'") {
            final nested = _readString(source, cursor);
            if (nested == null) break;
            cursor = nested.end;
            continue;
          }
          if (char == '{') {
            depth++;
          } else if (char == '}') {
            depth--;
            if (depth == 0) {
              cursor++;
              break;
            }
          }
          cursor++;
        }
        index = cursor;
        continue;
      }
      if (index + 1 < source.length &&
          _isIdentifierStart(source.codeUnitAt(index + 1))) {
        var cursor = index + 2;
        while (cursor < source.length && _isIdentifier(source.codeUnitAt(cursor))) {
          cursor++;
        }
        index = cursor;
        continue;
      }
    }

    if (!triple && source[index] == '\n') return null;
    index++;
  }
  return null;
}

class _StringLiteral {
  const _StringLiteral({required this.end, required this.body});

  /// Index just past the closing quote.
  final int end;

  /// Raw contents, escapes and interpolations untouched.
  final String body;
}

/// Resolves the escapes used when keys are written as Dart literals, so that a
/// key in the sources compares equal to the key in the catalog.
String _unescape(String raw) {
  final out = StringBuffer();
  for (var index = 0; index < raw.length; index++) {
    if (raw[index] == '\\' && index + 1 < raw.length) {
      out.write(switch (raw[index + 1]) {
        'n' => '\n',
        't' => '\t',
        'r' => '\r',
        final other => other,
      });
      index++;
      continue;
    }
    out.write(raw[index]);
  }
  return out.toString();
}

Iterable<File> _dartFiles(Directory directory) sync* {
  final entries = directory.listSync(recursive: true).whereType<File>();
  for (final file in entries) {
    if (file.path.endsWith('.dart')) yield file;
  }
}

/// Offsets at which each line starts, for O(log n) line lookups.
List<int> _lineStarts(String source) {
  final starts = <int>[0];
  for (var index = 0; index < source.length; index++) {
    if (source[index] == '\n') starts.add(index + 1);
  }
  return starts;
}

int _lineNumber(List<int> lineStarts, int offset) {
  var low = 0;
  var high = lineStarts.length - 1;
  while (low < high) {
    final mid = (low + high + 1) ~/ 2;
    if (lineStarts[mid] <= offset) {
      low = mid;
    } else {
      high = mid - 1;
    }
  }
  return low + 1;
}

bool _isIdentifier(int code) =>
    _isIdentifierStart(code) || (code >= 0x30 && code <= 0x39);

bool _isIdentifierStart(int code) =>
    (code >= 0x41 && code <= 0x5A) ||
    (code >= 0x61 && code <= 0x7A) ||
    code == 0x5F;

bool _isWhitespace(String char) =>
    char == ' ' || char == '\n' || char == '\r' || char == '\t';
