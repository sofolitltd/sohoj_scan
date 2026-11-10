import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/number_parser.dart';
import '../../core/operator.dart';
import '../../theme/sohoj_theme.dart';
import '../../theme/sohoj_tokens.dart';
import 'history_store.dart';
import 'relative_time.dart';

/// F12. See docs/design-system/components/HistoryRow/README.md.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.onClose, this.onOpenSettings});

  final VoidCallback? onClose;
  final VoidCallback? onOpenSettings;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _store = HistoryStore();
  List<HistoryEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _store.load();
    if (mounted) setState(() => _entries = entries);
  }

  Future<void> _copy(String number) async {
    await Clipboard.setData(ClipboardData(text: number));
    await HapticFeedback.mediumImpact();
  }

  Future<void> _clearAll() async {
    await _store.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.sohoj;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SohojSize.space2, vertical: SohojSize.space2),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onClose,
                    tooltip: 'ফিরে যান',
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text('আগের নাম্বার',
                        textAlign: TextAlign.center,
                        style: SohojType.title.copyWith(color: p.ink)),
                  ),
                  IconButton(
                    onPressed: widget.onOpenSettings,
                    tooltip: 'সেটিংস',
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _entries.isEmpty
                  ? Center(
                      child: Text('কোনো নাম্বার নেই',
                          style: SohojType.body.copyWith(color: p.inkMuted)),
                    )
                  : ListView.separated(
                      itemCount: _entries.length,
                      separatorBuilder: (_, __) => Divider(color: p.line, height: 1),
                      itemBuilder: (context, i) => _HistoryRow(
                        entry: _entries[i],
                        onCopy: () => _copy(_entries[i].number),
                      ),
                    ),
            ),
            if (_entries.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    SohojSize.space6, SohojSize.space4, SohojSize.space6, SohojSize.space8),
                child: OutlinedButton(
                  onPressed: _clearAll,
                  child: const Text('সব মুছুন'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.onCopy});

  final HistoryEntry entry;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final p = context.sohoj;
    final groups = groupNumber(entry.number);
    final op = Operator.fromNumber(entry.number);
    final time = relativeTimeBn(entry.scannedAt);

    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(horizontal: SohojSize.space6, vertical: SohojSize.space2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(groups.join(' '), style: SohojType.numberRow.copyWith(color: p.ink)),
                const SizedBox(height: 2),
                Text(
                  op != null ? '$time · ${op.label}' : time,
                  style: SohojType.caption.copyWith(color: p.inkMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            tooltip: 'কপি',
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
    );
  }
}
