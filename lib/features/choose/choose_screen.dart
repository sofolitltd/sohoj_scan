import 'package:flutter/material.dart';

import '../../core/number_parser.dart';
import '../../core/operator.dart';
import '../../theme/sohoj_theme.dart';
import '../../theme/sohoj_tokens.dart';

/// F09: shown when the scan box holds two or more valid numbers.
/// See docs/design-system/components/NumberCard/README.md.
class ChooseScreen extends StatelessWidget {
  const ChooseScreen({super.key, required this.numbers, required this.onPicked, this.onClose});

  /// Nearest-to-centre first (VoteBuffer already orders by vote count).
  final List<String> numbers;
  final void Function(String number) onPicked;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.sohoj;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  SohojSize.space4, SohojSize.space2, SohojSize.space4, SohojSize.space2),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onClose,
                    tooltip: 'ফিরে যান',
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: SohojSize.space2),
                  Text('কোনটা নাম্বার?', style: SohojType.title.copyWith(color: p.ink)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: SohojSize.space6, vertical: SohojSize.space4),
                itemCount: numbers.length,
                separatorBuilder: (_, __) => const SizedBox(height: SohojSize.space4),
                itemBuilder: (context, i) => _NumberCard(
                  number: numbers[i],
                  onTap: () => onPicked(numbers[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberCard extends StatelessWidget {
  const _NumberCard({required this.number, required this.onTap});

  final String number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.sohoj;
    final groups = groupNumber(number);
    final op = Operator.fromNumber(number);

    return Semantics(
      button: true,
      label: spokenNumber(number),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SohojSize.radiusLg),
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.all(SohojSize.space6),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(color: p.lineStrong, width: 2),
            borderRadius: BorderRadius.circular(SohojSize.radiusLg),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(groups.join(' '),
                        style: SohojType.numberCard.copyWith(color: p.ink)),
                    if (op != null) ...[
                      const SizedBox(height: SohojSize.space2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: SohojSize.space3, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.surfaceRaised,
                          borderRadius: BorderRadius.circular(SohojSize.radiusSm),
                        ),
                        child: Text(op.label,
                            style: SohojType.caption.copyWith(
                                color: p.ink, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.inkMuted, size: SohojSize.sizeIcon),
            ],
          ),
        ),
      ),
    );
  }
}
