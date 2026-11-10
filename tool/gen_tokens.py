#!/usr/bin/env python3
"""Regenerate lib/theme/sohoj_tokens.dart from docs/design-system/tokens.json.

Run from the project root:  python3 tool/gen_tokens.py
"""
import json, pathlib
ROOT = pathlib.Path(__file__).resolve().parent.parent
t = json.loads((ROOT / 'docs/design-system/tokens.json').read_text(encoding='utf-8'))

def argb(v):
    if v.startswith('rgba'):
        r, g, b, a = [x.strip() for x in v[5:-1].split(',')]
        return '0x%02X%02X%02X%02X' % (round(float(a) * 255), int(r), int(g), int(b))
    return '0xFF' + v.lstrip('#').upper()

def camel(n):
    p = n.split('-')
    return p[0] + ''.join(x.capitalize() for x in p[1:])

themes = [x['id'] for x in t['color']['themes']]
L = ['// GENERATED from docs/design-system/tokens.json — do not edit by hand.',
     '// Regenerate with: python3 tool/gen_tokens.py', '',
     "import 'package:flutter/painting.dart';", '',
     '/// One colour palette per theme (dark is the default).',
     'class SohojPalette {', '  const SohojPalette({']
L += [f'    required this.{camel(c["name"])},' for c in t['color']['tokens']]
L += ['  });', '']
for c in t['color']['tokens']:
    L += [f'  /// {c["usage"]}', f'  final Color {camel(c["name"])};']
L += ['}', '']
for th in themes:
    L.append(f'const SohojPalette sohoj{th.capitalize()} = SohojPalette(')
    L += [f'  {camel(c["name"])}: Color({argb(c["value"][th])}),' for c in t['color']['tokens']]
    L += [');', '']
L += ['/// Spacing, radius and size tokens in logical pixels (dp).', 'abstract final class SohojSize {']
for fam in ['spacing', 'radius', 'size']:
    for s in t[fam]['tokens']:
        L += [f'  /// {s["usage"]}', f'  static const double {camel(s["name"])} = {float(s["value"].replace("px", ""))};']
L += ['}', '', '/// Text style tokens (sizes in sp).', 'abstract final class SohojType {',
      "  static const String ui = 'AtkinsonHyperlegibleNext';",
      "  static const String bangla = 'NotoSansBengali';",
      "  static const String numeric = 'AtkinsonHyperlegibleMono';"]
for g in t['type']['groups']:
    for s in g['styles']:
        fs = float(s['fontSize'][:-2]); lh = float(s['lineHeight'][:-2])
        fam = 'numeric' if g['family'] == 'num' else 'ui'
        ls = f', letterSpacing: {round(float(s["letterSpacing"][:-2]) * fs, 2)}' if 'letterSpacing' in s else ''
        fb = '' if fam == 'numeric' else ', fontFamilyFallback: [bangla]'
        L += [f'  /// {s["usage"]}',
              f'  static const TextStyle {camel(s["name"])} = TextStyle(fontFamily: {fam}{fb}, fontSize: {fs}, height: {round(lh / fs, 3)}, fontWeight: FontWeight.w{s["fontWeight"]}{ls});']
L.append('}')
(ROOT / 'lib/theme/sohoj_tokens.dart').write_text('\n'.join(L) + '\n', encoding='utf-8')
print('wrote lib/theme/sohoj_tokens.dart')
