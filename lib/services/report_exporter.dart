import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/utils/formatters.dart';
import '../models/expense_record.dart';
import '../models/product.dart';
import '../models/sale_record.dart';

class ReportExporter {
  Future<String> exportSalesReport({
    required List<Product> products,
    required List<SaleRecord> sales,
    required List<ExpenseRecord> expenses,
    required DateTime from,
    required DateTime to,
  }) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load(
      'assets/fonts/NotoSansArabic-Regular.ttf',
    );
    final arabicFont = pw.Font.ttf(fontData);
    final salesByProduct = <String, _ProductSalesRow>{};

    for (final sale in sales) {
      salesByProduct.update(
        sale.productId,
        (current) => current.copyWith(
          quantityMm: current.quantityMm + sale.quantityMm,
          totalSales: current.totalSales + sale.finalTotal,
          saleCount: current.saleCount + 1,
        ),
        ifAbsent: () => _ProductSalesRow(
          productName: sale.productName,
          quantityMm: sale.quantityMm,
          totalSales: sale.finalTotal,
          saleCount: 1,
        ),
      );
    }

    final rankedProducts = salesByProduct.values.toList()
      ..sort((a, b) => b.totalSales.compareTo(a.totalSales));
    final bestProduct = rankedProducts.isEmpty ? null : rankedProducts.first;
    final totalSales = sales.fold<double>(0, (sum, sale) => sum + sale.finalTotal);
    final totalSoldQuantity = sales.fold<double>(0, (sum, sale) => sum + sale.quantityMm);
    final totalExpenses = expenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final netProfit =
        totalSales -
        products.fold<double>(0, (sum, product) => sum + product.stockValue) -
        totalExpenses;

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: arabicFont),
        textDirection: pw.TextDirection.rtl,
        pageFormat: PdfPageFormat.a4,
        build: (context) => <pw.Widget>[
          pw.Text(
            'Sales Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Period: ${formatDateOnly(from)} to ${formatDateOnly(to)}'),
          pw.Text('Generated: ${formatDateTime(DateTime.now())}'),
          pw.SizedBox(height: 18),
          pw.Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <pw.Widget>[
              _summaryBox('Products', '${products.length}'),
              _summaryBox('Sales count', '${sales.length}'),
              _summaryBox('Sold quantity', formatMillimeters(totalSoldQuantity)),
              _summaryBox('Sales value', formatCurrency(totalSales)),
              _summaryBox('Expenses', formatCurrency(totalExpenses)),
              _summaryBox('Net profit', formatCurrency(netProfit)),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Best Product',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            bestProduct == null
                ? 'No sales in the selected period.'
                : '${bestProduct.productName} - ${formatCurrency(bestProduct.totalSales)} from ${bestProduct.saleCount} sale(s), ${formatMillimeters(bestProduct.quantityMm)} sold.',
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Current Stock',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const <String>['Product', 'Stock', 'Sell Price/mm', 'Stock Value'],
            data: products
                .map(
                  (product) => <String>[
                    product.name,
                    formatMillimeters(product.quantityMm),
                    formatCurrency(product.sellPrice),
                    formatCurrency(product.stockValue),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Expenses',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          expenses.isEmpty
              ? pw.Text('No expenses in the selected period.')
              : pw.TableHelper.fromTextArray(
                  headers: const <String>['Date', 'Amount', 'Reason'],
                  data: expenses
                      .map(
                        (expense) => <String>[
                          formatDateOnly(expense.date),
                          formatCurrency(expense.amount),
                          expense.reason,
                        ],
                      )
                      .toList(),
                ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Sales Ranking',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const <String>['Product', 'Sales', 'Quantity Sold', 'Sale Count'],
            data: rankedProducts
                .map(
                  (row) => <String>[
                    row.productName,
                    formatCurrency(row.totalSales),
                    formatMillimeters(row.quantityMm),
                    '${row.saleCount}',
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Sale Details',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const <String>['Date', 'Product', 'Customer', 'Qty', 'Total'],
            data: sales
                .map(
                  (sale) => <String>[
                    formatDateTime(sale.soldAt),
                    sale.productName,
                    sale.customerName == null
                        ? 'Regular customer'
                        : '${sale.customerId ?? ''} ${sale.customerName!}'.trim(),
                    formatMillimeters(sale.quantityMm),
                    formatCurrency(sale.finalTotal),
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final file = await _createReportFile(from: from, to: to);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  pw.Widget _summaryBox(String label, String value) {
    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  Future<File> _createReportFile({
    required DateTime from,
    required DateTime to,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final reportsDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}reports',
    );
    if (!await reportsDirectory.exists()) {
      await reportsDirectory.create(recursive: true);
    }

    final fileName =
        'sales_report_${formatDateForFileName(from)}_${formatDateForFileName(to)}.pdf';
    return File('${reportsDirectory.path}${Platform.pathSeparator}$fileName');
  }
}

class _ProductSalesRow {
  const _ProductSalesRow({
    required this.productName,
    required this.quantityMm,
    required this.totalSales,
    required this.saleCount,
  });

  final String productName;
  final double quantityMm;
  final double totalSales;
  final int saleCount;

  _ProductSalesRow copyWith({
    String? productName,
    double? quantityMm,
    double? totalSales,
    int? saleCount,
  }) {
    return _ProductSalesRow(
      productName: productName ?? this.productName,
      quantityMm: quantityMm ?? this.quantityMm,
      totalSales: totalSales ?? this.totalSales,
      saleCount: saleCount ?? this.saleCount,
    );
  }
}
