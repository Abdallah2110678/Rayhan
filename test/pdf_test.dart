import 'package:flutter_test/flutter_test.dart';

import 'package:rehana/models/expense_record.dart';
import 'package:rehana/models/product.dart';
import 'package:rehana/models/sale_record.dart';
import 'package:rehana/services/report_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PDF generation test', () async {
    final products = [
      Product(
        id: '1',
        name: 'Test Product',
        purchasePrice: 10.0,
        sellPrice: 15.0,
        quantityMm: 100.0,
        initialQuantityMm: 100.0,
      ),
    ];

    final sales = [
      SaleRecord(
        id: '1',
        productId: '1',
        productName: 'Test Product',
        quantityMm: 50.0,
        unitPrice: 15.0,
        discountPercent: 0.0,
        subtotal: 750.0,
        finalTotal: 750.0,
        soldAt: DateTime.now(),
        customerId: '1',
        customerName: 'Test Customer',
      ),
    ];

    final expenses = [
      ExpenseRecord(
        id: '1',
        date: DateTime.now(),
        amount: 100.0,
        reason: 'Test expense',
      ),
    ];

    final from = DateTime.now().subtract(const Duration(days: 30));
    final to = DateTime.now();

    final exporter = ReportExporter();

    try {
      await exporter.exportSalesReport(
        products: products,
        sales: sales,
        expenses: expenses,
        from: from,
        to: to,
      );
    } catch (error, stackTrace) {
      fail('PDF generation failed: $error\n$stackTrace');
    }
  });
}
