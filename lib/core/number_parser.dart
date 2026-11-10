/// Finds Bangladeshi mobile numbers in OCR text.
///
/// Pure Dart: no Flutter, no camera. Every rule lives in docs/PRD.md
/// ("Number parsing নিয়ম") and is covered by test/number_parser_test.dart.
library;

/// Letters OCR often returns in place of digits. Applied only inside tokens
/// that already look mostly numeric, so ordinary words are left alone.
const Map<String, String> _lookalikes = {
  'O': '0', 'o': '0', 'D': '0', 'Q': '0',
  'I': '1', 'l': '1', '|': '1', 'i': '1', 'L': '1',
  'Z': '2', 'z': '2',
  'A': '4',
  'S': '5', 's': '5',
  'G': '6', 'b': '6',
  'T': '7',
  'B': '8',
  'g': '9', 'q': '9',
};

const String _separators = '+-.()';

/// 0 1 [3-9] + 8 digits, separators allowed between digits, with an optional
/// +88 / 0088 / 88 country prefix. Not part of a longer digit run.
final RegExp _number = RegExp(
  r'(?<![0-9])(?:(?:\+|00)?88[\s\-.]*)?(0[\s\-.()]*1[\s\-.()]*[3-9](?:[\s\-.()]*[0-9]){8})(?![0-9])',
);

final RegExp _nonDigit = RegExp(r'\D');
final RegExp _whitespace = RegExp(r'\s+');

bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

/// Replaces look-alike letters with digits when at least 2 characters are
/// real digits and at least 60% are digits or look-alikes.
String _normalizeToken(String token) {
  var digits = 0, lookalike = 0, separators = 0;
  for (final c in token.split('')) {
    if (_isDigit(c)) {
      digits++;
    } else if (_lookalikes.containsKey(c)) {
      lookalike++;
    } else if (_separators.contains(c)) {
      separators++;
    }
  }
  final core = token.length - separators;
  if (digits >= 2 && core > 0 && (digits + lookalike) / core >= 0.6) {
    return token.split('').map((c) => _lookalikes[c] ?? c).join();
  }
  return token;
}

/// Returns every valid number in [text] as 11 plain digits (`01712345678`),
/// in reading order, without duplicates.
List<String> findNumbers(String text) {
  final found = <String>[];
  for (final rawLine in text.split('\n')) {
    final line = rawLine
        .trim()
        .split(_whitespace)
        .where((t) => t.isNotEmpty)
        .map(_normalizeToken)
        .join(' ');
    for (final m in _number.allMatches(line)) {
      final n = m.group(1)!.replaceAll(_nonDigit, '');
      if (!found.contains(n)) found.add(n);
    }
  }
  return found;
}

/// `01712345678` → `['017', '1234', '5678']`.
List<String> groupNumber(String number) {
  assert(number.length == 11, 'expects 11 digits');
  return [number.substring(0, 3), number.substring(3, 7), number.substring(7)];
}

/// Text for TTS and TalkBack: "0 1 7, 1 2 3 4, 5 6 7 8".
String spokenNumber(String number) =>
    groupNumber(number).map((g) => g.split('').join(' ')).join(', ');
