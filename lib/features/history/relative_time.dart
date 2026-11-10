const _banglaDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

String _bn(int n) => n.toString().split('').map((d) => _banglaDigits[int.parse(d)]).join();

/// "২ মিনিট আগে" / "১ ঘণ্টা আগে", matching design/screens.html's history rows.
String relativeTimeBn(DateTime from, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(from);
  if (diff.inMinutes < 1) return 'এখনই';
  if (diff.inMinutes < 60) return '${_bn(diff.inMinutes)} মিনিট আগে';
  return '${_bn(diff.inHours)} ঘণ্টা আগে';
}
