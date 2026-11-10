/// Mobile operator from the number prefix.
///
/// Check this table against BTRC's current list before release.
enum Operator {
  grameenphone('Grameenphone'),
  robi('Robi'),
  airtel('Airtel'),
  banglalink('Banglalink'),
  teletalk('Teletalk');

  const Operator(this.label);
  final String label;

  /// Returns null for an unknown prefix: the UI then hides the chip.
  static Operator? fromNumber(String number) {
    if (number.length < 3) return null;
    switch (number.substring(0, 3)) {
      case '013':
      case '017':
        return Operator.grameenphone;
      case '018':
        return Operator.robi;
      case '016':
        return Operator.airtel;
      case '014':
      case '019':
        return Operator.banglalink;
      case '015':
        return Operator.teletalk;
    }
    return null;
  }
}
