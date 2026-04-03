import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../core/utils/formatters.dart';
import '../core/utils/translator.dart';
import '../services/data_porter.dart';
import '../services/report_exporter.dart';
import '../state/customer_controller.dart';
import '../state/expense_controller.dart';
import '../state/product_catalog_controller.dart';
import '../widgets/page_header.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.products,
    required this.customers,
    required this.expenses,
  });

  final ProductCatalogController products;
  final CustomerController customers;
  final ExpenseController expenses;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ReportExporter _reportExporter = ReportExporter();
  final DataPorter _dataPorter = DataPorter();

  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isExporting = false;
  bool _isDataExporting = false;
  bool _isDataImporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _toDate = DateTime(now.year, now.month, now.day);
    _fromDate = DateTime(now.year, now.month, 1);
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: _toDate ?? DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _fromDate = DateTime(picked.year, picked.month, picked.day);
      if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
        _toDate = _fromDate;
      }
    });
  }

  Future<void> _pickToDate() async {
    final initialDate = _toDate ?? _fromDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _toDate = DateTime(picked.year, picked.month, picked.day);
      if (_fromDate != null && _fromDate!.isAfter(_toDate!)) {
        _fromDate = _toDate;
      }
    });
  }

  Future<void> _exportReport() async {
    final from = _fromDate;
    final to = _toDate;
    if (from == null || to == null) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final sales = widget.products.salesBetween(from, to);
      final path = await _reportExporter.exportSalesReport(
        products: widget.products.products.toList(growable: false),
        sales: sales,
        expenses: widget.expenses.expenses.toList(growable: false),
        from: from,
        to: to,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('PDF report saved to $path')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Could not export report: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _exportAllData() async {
    setState(() {
      _isDataExporting = true;
    });

    try {
      final path = await _dataPorter.exportAllData(
        products: widget.products,
        customers: widget.customers,
        expenses: widget.expenses,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('All data exported to $path')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Export failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isDataExporting = false;
        });
      }
    }
  }

  Future<void> _importAllData() async {
    setState(() {
      _isDataImporting = true;
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final files =
          Directory(directory.path)
              .listSync()
              .whereType<File>()
              .where((file) => file.path.endsWith('.json'))
              .toList()
            ..sort((b, a) => a.path.compareTo(b.path));

      if (files.isEmpty) {
        throw Exception('No export file found in app folder');
      }

      final path = files.first.path; // latest by name sorting
      await _dataPorter.importAllData(
        products: widget.products,
        customers: widget.customers,
        expenses: widget.expenses,
        filePath: path,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Imported data from $path')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Import failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isDataImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        widget.products,
        widget.customers,
        widget.expenses,
      ]),
      builder: (context, _) {
        final from = _fromDate ?? DateTime.now();
        final to = _toDate ?? from;
        final filteredSales = widget.products.salesBetween(from, to);
        final filteredSalesValue = widget.products.totalSalesValueBetween(from, to);
        final filteredSoldQuantity = widget.products.totalSoldQuantityBetween(from, to);
        final bestProduct = widget.products.bestSellingProductBetween(from, to);

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PageHeader(
                title: Translator.translate('home_statistics'),
                subtitle: Translator.translate('dashboard_subtitle'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              _DateChip(
                                label: Translator.translate('from'),
                                value: formatDateOnly(from),
                                onTap: _pickFromDate,
                              ),
                              _DateChip(
                                label: Translator.translate('to'),
                                value: formatDateOnly(to),
                                onTap: _pickToDate,
                              ),
                              FilledButton.icon(
                                onPressed: _isExporting ? null : _exportReport,
                                icon: _isExporting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.picture_as_pdf_outlined),
                                label: Text(
                                  _isExporting
                                      ? Translator.translate('generating')
                                      : Translator.translate('generate_pdf'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          FilledButton.icon(
                            onPressed: _isDataExporting ? null : _exportAllData,
                            icon: _isDataExporting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload_file),
                            label: Text(
                              _isDataExporting
                                  ? Translator.translate('exporting')
                                  : Translator.translate('export_all_data'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: _isDataImporting ? null : _importAllData,
                            icon: _isDataImporting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.download),
                            label: Text(
                              _isDataImporting
                                  ? Translator.translate('importing')
                                  : Translator.translate('import_latest_data'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: <Widget>[
                          _StatCard(
                            title: Translator.translate('total_bought'),
                            value: formatCurrency(widget.products.totalPurchaseValue),
                            note: formatMillimeters(widget.products.totalPurchasedQuantityMm),
                            color: const Color(0xFF8A5A24),
                            icon: Icons.shopping_bag_outlined,
                          ),
                          _StatCard(
                            title: Translator.translate('sold_in_range'),
                            value: formatCurrency(filteredSalesValue),
                            note: formatMillimeters(filteredSoldQuantity),
                            color: const Color(0xFF18534F),
                            icon: Icons.point_of_sale_outlined,
                          ),
                          _StatCard(
                            title: Translator.translate('total_expenses'),
                            value: formatCurrency(
                              widget.expenses.totalExpenses,
                            ),
                            note: '${widget.expenses.expenseCount} entries',
                            color: const Color(0xFFD32F2F),
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                          _StatCard(
                            title: Translator.translate('sales_count'),
                            value: '${filteredSales.length}',
                            note: '${formatDateOnly(from)} to ${formatDateOnly(to)}',
                            color: const Color(0xFF316B83),
                            icon: Icons.filter_alt_outlined,
                          ),
                          _StatCard(
                            title: Translator.translate('inventory_value'),
                            value: formatCurrency(widget.products.totalInventoryValue),
                            note: formatMillimeters(widget.products.totalQuantityMm),
                            color: const Color(0xFFB05335),
                            icon: Icons.inventory_2_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: <Widget>[
                          _MiniCard(
                            label: Translator.translate('products'),
                            value: '${widget.products.productCount}',
                            icon: Icons.category_outlined,
                          ),
                          _MiniCard(
                            label: Translator.translate('customers'),
                            value: '${widget.customers.customerCount}',
                            icon: Icons.groups_2_outlined,
                          ),
                          _MiniCard(
                            label: Translator.translate('all_time_sold'),
                            value: formatMillimeters(widget.products.totalSoldQuantityMm),
                            icon: Icons.straighten,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        Translator.translate('low_stock_alerts'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final lowStockProducts = widget.products.products
                              .where((product) => product.quantityMm <= 110)
                              .toList();
                          return lowStockProducts.isEmpty
                              ? Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      Translator.translate('all_products_healthy'),
                                      style: const TextStyle(color: Colors.green),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: lowStockProducts
                                      .map(
                                        (product) => Card(
                                          color: Colors.red.shade50,
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              children: <Widget>[
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Colors.red.shade700,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: <Widget>[
                                                      Text(
                                                        product.name,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        'Stock: ${formatMillimeters(product.quantityMm)}',
                                                        style: TextStyle(
                                                          color: Colors
                                                              .red
                                                              .shade700,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        Translator.translate('product_stock_levels'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: <DataColumn>[
                                DataColumn(label: Text(Translator.translate('product'))),
                                DataColumn(label: Text(Translator.translate('quantity_in_mm'))),
                                DataColumn(label: Text(Translator.translate('status'))),
                              ],
                              rows: widget.products.products
                                  .map(
                                    (product) => DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text(product.name)),
                                        DataCell(
                                          Text(
                                            formatMillimeters(
                                              product.quantityMm,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: product.quantityMm <= 110
                                                  ? Colors.red.shade100
                                                  : product.quantityMm <= 200
                                                  ? Colors.orange.shade100
                                                  : Colors.green.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              product.quantityMm <= 110
                                                  ? Translator.translate('low')
                                                  : product.quantityMm <= 200
                                                      ? Translator.translate('medium')
                                                      : Translator.translate('healthy'),
                                              style: TextStyle(
                                                color: product.quantityMm <= 110
                                                    ? Colors.red.shade700
                                                    : product.quantityMm <= 200
                                                    ? Colors.orange.shade700
                                                    : Colors.green.shade700,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                Translator.translate('best_selling_product'),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                bestProduct == null
                                    ? Translator.translate('no_sales_in_range')
                                    : '${bestProduct.productName} generated ${formatCurrency(filteredSales.where((sale) => sale.productId == bestProduct.productId).fold<double>(0, (sum, sale) => sum + sale.finalTotal))} from ${formatMillimeters(filteredSales.where((sale) => sale.productId == bestProduct.productId).fold<double>(0, (sum, sale) => sum + sale.quantityMm))}.',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: const Color(0xFF5B635E),
                                      height: 1.45,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_month_outlined),
      label: Text('$label: $value'),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.note,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final String note;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF173531),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                note,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF5B635E),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, size: 18, color: const Color(0xFF5B635E)),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF5B635E),
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF173531),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
