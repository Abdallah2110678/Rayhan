abstract final class IdGenerator {
  static int _counter = 0;

  static String _make(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';
  }

  static String product() => _make('product');
  static String sale() => _make('sale');
  static String customer() => _make('customer');
  static String expense() => _make('expense');
}
