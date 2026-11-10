import 'package:flutter_test/flutter_test.dart';
import 'package:sohoj_scan/core/spoken_digits.dart';

void main() {
  group('digitsFromSpeech', () {
    test('plain digits', () {
      expect(digitsFromSpeech('zero one seven one two three four five six seven eight'),
          '01712345678');
    });
    test('oh means zero', () {
      expect(digitsFromSpeech('oh one seven'), '017');
    });
    test('double and triple', () {
      expect(digitsFromSpeech('zero one seven double five triple nine'), '01755999');
    });
    test('unknown words are skipped', () {
      expect(digitsFromSpeech('[unk] zero one [unk] seven'), '017');
    });
    test('trailing double waits for its digit', () {
      expect(digitsFromSpeech('zero one double'), '01');
    });
    test('case and extra spaces', () {
      expect(digitsFromSpeech('  Zero   ONE seven '), '017');
    });
  });

  group('numberFromSpeech', () {
    test('valid number', () {
      expect(numberFromSpeech('zero one seven one two three four five six seven eight'),
          '01712345678');
    });
    test('with 88 prefix', () {
      expect(numberFromSpeech('eight eight zero one eight one two three four five six seven eight'),
          '01812345678');
    });
    test('with double and triple', () {
      expect(numberFromSpeech('zero one nine double five triple one two three four'),
          '01955111234');
    });
    test('too short is null', () {
      expect(numberFromSpeech('zero one seven one two three'), isNull);
    });
    test('wrong operator prefix is null', () {
      expect(numberFromSpeech('zero one two one two three four five six seven eight'), isNull);
    });
    test('twelve digits is null', () {
      expect(numberFromSpeech('zero one seven one two three four five six seven eight nine'),
          isNull);
    });
  });

  group('slotsFromSpeech', () {
    test('fills left to right, rest null', () {
      final s = slotsFromSpeech('zero one seven');
      expect(s.length, 11);
      expect(s.take(3), ['0', '1', '7']);
      expect(s.skip(3).every((e) => e == null), isTrue);
    });
    test('hides 88 prefix', () {
      expect(slotsFromSpeech('eight eight zero one seven').take(3), ['0', '1', '7']);
    });
  });

  test('grammar has 13 words plus [unk]', () {
    expect(kVoskGrammar.length, 14);
    expect(kVoskGrammar, contains('[unk]'));
  });
}
