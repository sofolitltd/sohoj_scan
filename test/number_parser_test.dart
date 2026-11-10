import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sohoj_scan/core/number_parser.dart';
import 'package:sohoj_scan/core/operator.dart';
import 'package:sohoj_scan/core/vote_buffer.dart';

void main() {
  group('findNumbers — fixtures', () {
    final cases = jsonDecode(File('test/fixtures/number_cases.json').readAsStringSync()) as List;
    for (final c in cases) {
      final input = c['input'] as String;
      final expected = (c['expected'] as List).cast<String>();
      test(input.replaceAll('\n', r'\n'), () {
        expect(findNumbers(input), expected);
      });
    }
  });

  test('groupNumber and spokenNumber', () {
    expect(groupNumber('01712345678'), ['017', '1234', '5678']);
    expect(spokenNumber('01712345678'), '0 1 7, 1 2 3 4, 5 6 7 8');
  });

  test('operator from prefix', () {
    expect(Operator.fromNumber('01712345678'), Operator.grameenphone);
    expect(Operator.fromNumber('01312345678'), Operator.grameenphone);
    expect(Operator.fromNumber('01812345678'), Operator.robi);
    expect(Operator.fromNumber('01612345678'), Operator.airtel);
    expect(Operator.fromNumber('01412345678'), Operator.banglalink);
    expect(Operator.fromNumber('01912345678'), Operator.banglalink);
    expect(Operator.fromNumber('01512345678'), Operator.teletalk);
    expect(Operator.fromNumber('01112345678'), isNull);
  });

  group('VoteBuffer (3 of 5)', () {
    test('locks only after 3 sightings', () {
      final v = VoteBuffer();
      expect(v.add(['01712345678']), isEmpty);
      expect(v.add(['01712345678']), isEmpty);
      expect(v.add(['01772345678']), isEmpty); // one-frame misread
      expect(v.add(['01712345678']), ['01712345678']);
    });

    test('old frames fall out of the window', () {
      final v = VoteBuffer();
      v.add(['01712345678']);
      v.add(['01712345678']);
      for (var i = 0; i < 4; i++) {
        v.add(const []);
      }
      expect(v.add(['01712345678']), isEmpty);
    });
  });
}
