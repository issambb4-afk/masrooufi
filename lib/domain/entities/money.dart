import 'package:intl/intl.dart';

class Money {
  final int minorUnits;
  final String currencyCode;

  const Money(this.minorUnits, {this.currencyCode = 'TND'});

  /// Get the multiplier based on currency precision.
  /// Hardcoded to TND (3 decimals) and standard fallback (2 decimals) for now.
  int get _multiplier => currencyCode.toUpperCase() == 'TND' ? 1000 : 100;

  double get asDouble => minorUnits / _multiplier;

  /// Returns a localized string representation of the money amount.
  String format(String locale) {
    final format = NumberFormat.currency(
      locale: locale,
      name: currencyCode,
      symbol: currencyCode, // Or map to proper symbols if needed
      decimalDigits: currencyCode.toUpperCase() == 'TND' ? 3 : 2,
    );
    return format.format(asDouble);
  }

  /// Safely parses a double to minor units based on currency precision
  static int parseToMinorUnits(double amount, {String currencyCode = 'TND'}) {
    final multiplier = currencyCode.toUpperCase() == 'TND' ? 1000 : 100;
    return (amount * multiplier).round();
  }

  Money operator +(Money other) {
    assert(currencyCode == other.currencyCode, 'Cannot add different currencies');
    return Money(minorUnits + other.minorUnits, currencyCode: currencyCode);
  }

  Money operator -(Money other) {
    assert(currencyCode == other.currencyCode, 'Cannot subtract different currencies');
    return Money(minorUnits - other.minorUnits, currencyCode: currencyCode);
  }

  bool operator >(Money other) {
    assert(currencyCode == other.currencyCode, 'Cannot compare different currencies');
    return minorUnits > other.minorUnits;
  }

  bool operator <(Money other) {
    assert(currencyCode == other.currencyCode, 'Cannot compare different currencies');
    return minorUnits < other.minorUnits;
  }

  bool operator >=(Money other) {
    assert(currencyCode == other.currencyCode, 'Cannot compare different currencies');
    return minorUnits >= other.minorUnits;
  }

  bool operator <=(Money other) {
    assert(currencyCode == other.currencyCode, 'Cannot compare different currencies');
    return minorUnits <= other.minorUnits;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          runtimeType == other.runtimeType &&
          minorUnits == other.minorUnits &&
          currencyCode == other.currencyCode;

  @override
  int get hashCode => minorUnits.hashCode ^ currencyCode.hashCode;
}
