abstract final class IdGenerator {
  static String product() => 'product_${DateTime.now().microsecondsSinceEpoch}';
  static String sale() => 'sale_${DateTime.now().microsecondsSinceEpoch}';
}

