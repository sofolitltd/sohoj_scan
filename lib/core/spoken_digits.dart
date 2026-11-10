/// Turns English digit words from the speech recognizer into digits.
///
/// Pure Dart. The recognizer (Vosk) is limited to [kVoskGrammar], so the
/// input is always a space-separated list of these words, maybe with "[unk]".
/// Rules: docs/PRD.md → F16.
library;

import 'number_parser.dart';

/// The only words the recognizer may return. Pass this to Vosk as the
/// grammar (as a JSON array). "[unk]" lets it reject noise instead of
/// forcing a digit.
const List<String> kVoskGrammar = [
  'zero', 'oh', 'one', 'two', 'three', 'four',
  'five', 'six', 'seven', 'eight', 'nine',
  'double', 'triple', '[unk]',
];

const Map<String, String> _digit = {
  'zero': '0', 'oh': '0', 'o': '0',
  'one': '1', 'two': '2', 'three': '3', 'four': '4', 'five': '5',
  'six': '6', 'seven': '7', 'eight': '8', 'nine': '9',
};

const Map<String, int> _repeat = {'double': 2, 'triple': 3};

/// "zero one seven double five" → "01755".
/// Unknown words are skipped. A "double"/"triple" with no digit after it
/// (yet) is ignored, so partial results never show a wrong digit.
String digitsFromSpeech(String text) {
  final words = text.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final out = StringBuffer();
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    final times = _repeat[w];
    if (times != null) {
      if (i + 1 < words.length && _digit.containsKey(words[i + 1])) {
        out.write(_digit[words[i + 1]]! * times);
        i++; // the digit is consumed
      }
      continue;
    }
    final d = _digit[w];
    if (d != null) out.write(d);
  }
  return out.toString();
}

/// The valid 11-digit number in [text], or null if there is none yet.
/// Reuses [findNumbers], so "+88"/"88" prefixes and validation stay identical
/// to the camera path.
String? numberFromSpeech(String text) {
  final found = findNumbers(digitsFromSpeech(text));
  return found.isEmpty ? null : found.first;
}

/// For the 11 slots on screen: "01712" → ['0','1','7','1','2',null,…] (length 11).
/// A leading "88" is hidden while the number is being spoken.
List<String?> slotsFromSpeech(String text) {
  var d = digitsFromSpeech(text);
  if (d.startsWith('880')) d = d.substring(2);
  return List<String?>.generate(11, (i) => i < d.length ? d[i] : null);
}
