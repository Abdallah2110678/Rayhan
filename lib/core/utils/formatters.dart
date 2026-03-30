String formatCurrency(double value) => '\$${value.toStringAsFixed(2)}';

String formatMillimeters(double value) => '${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)} mm';

String formatDiscount(double value) => '${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}%';

String formatDateOnly(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String formatDateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${formatDateOnly(value)} $hour:$minute';
}

String formatDateForFileName(DateTime value) {
  return formatDateOnly(value).replaceAll('-', '');
}
