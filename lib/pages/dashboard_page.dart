import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../core/app_constants.dart';
import '../core/utils/formatters.dart';
import '../core/utils/translator.dart';
import '../services/data_porter.dart';
import '../services/report_exporter.dart';
import '../state/customer_controller.dart';
import '../state/expense_controller.dart';
import '../state/product_catalog_controller.dart';
import '../widgets/collapsing_header_page.dart';
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
      final products = widget.products.products.toList(growable: false);
      final expenses = widget.expenses.expenses.toList(growable: false);

      if (products.isEmpty && sales.isEmpty && expenses.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(Translator.translate('pdf_report_no_data'))),
          );
        return;
      }

      final path = await _reportExporter.exportSalesReport(
        products: products,
        sales: sales,
        expenses: expenses,
        from: from,
        to: to,
      );

      if (!mounted) {
        return;
      }

      debugPrint('PDF report saved to: $path');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(Translator.translate('pdf_report_saved_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Translator.translate('pdf_report_saved_message', {
                  'path': path,
                }),
              ),
              const SizedBox(height: 16),
              Text(
                'File: rayhan_report.pdf',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final file = File(path);
                  if (await file.exists()) {
                    final result = await OpenFile.open(file.path);
                    if (result.type != ResultType.done) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not open PDF automatically. Use the file path above in a file manager.',
                          ),
                        ),
                      );
                    }
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('PDF not found at saved path.')),
                    );
                  }
                } catch (e) {
                  debugPrint('Could not open file: $e');
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not open PDF automatically. Please check path in dialog and open manually.',
                      ),
                    ),
                  );
                }
              },
              child: Text(Translator.translate('open_file')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(Translator.translate('ok')),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              Translator.translate('pdf_report_error', {
                'error': error.toString(),
              }),
            ),
          ),
        );
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
      final savedPath = await _dataPorter.exportAllData(
        products: widget.products,
        customers: widget.customers,
        expenses: widget.expenses,
      );
      if (!mounted) return;
      if (savedPath != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                Translator.translate('all_data_exported', {'path': savedPath}),
              ),
            ),
          );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              Translator.translate('pdf_report_error', {
                'error': error.toString(),
              }),
            ),
          ),
        );
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
      final result = await _dataPorter.importAllData(
        products: widget.products,
        customers: widget.customers,
        expenses: widget.expenses,
      );

      if (!mounted) return;

      if (result == null) {
        // user cancelled the file picker
        return;
      }

      showDialog<void>(
        context: context,
        builder: (context) => _ImportResultDialog(result: result),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              Translator.translate('import_data_failed', {
                'error': error.toString(),
              }),
            ),
          ),
        );
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

        return CollapsingHeaderPage(
          header: PageHeader(
            title: Translator.translate('home_statistics'),
            subtitle: Translator.translate('dashboard_subtitle'),
          ),
          child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // ── Date range card ──────────────────────────────────
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _DateContainer(
                                      label: Translator.translate('from'),
                                      value: formatDateOnly(from),
                                      onTap: _pickFromDate,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _DateContainer(
                                      label: Translator.translate('to'),
                                      value: formatDateOnly(to),
                                      onTap: _pickToDate,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
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
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── Export / import data buttons (outside the card) ──
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isDataExporting ? null : _exportAllData,
                              icon: _isDataExporting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.upload_file),
                              label: Text(
                                _isDataExporting
                                    ? Translator.translate('exporting')
                                    : Translator.translate('export_all_data'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isDataImporting ? null : _importAllData,
                              icon: _isDataImporting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.download),
                              label: Text(
                                _isDataImporting
                                    ? Translator.translate('importing')
                                    : Translator.translate('import_latest_data'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Stat cards grid ───────────────────────────────────
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth >= 600 ? 2 : 1;
                          final cardData = <_StatCardData>[
                            _StatCardData(
                              title: Translator.translate('total_bought'),
                              value: formatCurrency(widget.products.totalPurchaseValue),
                              note: formatMillimeters(widget.products.totalPurchasedQuantityMm),
                              color: const Color(0xFF8A5A24),
                              icon: Icons.shopping_bag_outlined,
                            ),
                            _StatCardData(
                              title: Translator.translate('sold_in_range'),
                              value: formatCurrency(filteredSalesValue),
                              note: formatMillimeters(filteredSoldQuantity),
                              color: const Color(0xFF18534F),
                              icon: Icons.point_of_sale_outlined,
                            ),
                            _StatCardData(
                              title: Translator.translate('total_expenses'),
                              value: formatCurrency(widget.expenses.totalExpenses),
                              note: '${widget.expenses.expenseCount} entries',
                              color: const Color(0xFFD32F2F),
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                            _StatCardData(
                              title: Translator.translate('sales_count'),
                              value: '${filteredSales.length}',
                              note: '${formatDateOnly(from)} to ${formatDateOnly(to)}',
                              color: const Color(0xFF316B83),
                              icon: Icons.filter_alt_outlined,
                            ),
                            _StatCardData(
                              title: Translator.translate('inventory_value'),
                              value: formatCurrency(widget.products.totalInventoryValue),
                              note: formatMillimeters(widget.products.totalQuantityMm),
                              color: const Color(0xFFB05335),
                              icon: Icons.inventory_2_outlined,
                            ),
                          ];
                          // Compute item height so GridView shrink-wraps correctly.
                          final itemHeight = 148.0;
                          final rows = (cardData.length / crossAxisCount).ceil();
                          final gridHeight = rows * itemHeight + (rows - 1) * 12.0;
                          return SizedBox(
                            height: gridHeight,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                mainAxisExtent: itemHeight,
                              ),
                              itemCount: cardData.length,
                              itemBuilder: (context, index) {
                                final d = cardData[index];
                                return _StatCard(
                                  title: d.title,
                                  value: d.value,
                                  note: d.note,
                                  color: d.color,
                                  icon: d.icon,
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── Mini cards grid ───────────────────────────────────
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth >= 600 ? 2 : 1;
                          final miniData = <_MiniCardData>[
                            _MiniCardData(
                              label: Translator.translate('products'),
                              value: '${widget.products.productCount}',
                              icon: Icons.category_outlined,
                            ),
                            _MiniCardData(
                              label: Translator.translate('customers'),
                              value: '${widget.customers.customerCount}',
                              icon: Icons.groups_2_outlined,
                            ),
                            _MiniCardData(
                              label: Translator.translate('all_time_sold'),
                              value: formatMillimeters(widget.products.totalSoldQuantityMm),
                              icon: Icons.straighten,
                            ),
                          ];
                          final itemHeight = 88.0;
                          final rows = (miniData.length / crossAxisCount).ceil();
                          final gridHeight = rows * itemHeight + (rows - 1) * 12.0;
                          return SizedBox(
                            height: gridHeight,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                mainAxisExtent: itemHeight,
                              ),
                              itemCount: miniData.length,
                              itemBuilder: (context, index) {
                                final d = miniData[index];
                                return _MiniCard(
                                  label: d.label,
                                  value: d.value,
                                  icon: d.icon,
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      // ── Low stock alerts ──────────────────────────────────
                      _SectionHeader(title: Translator.translate('low_stock_alerts')),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final lowStockProducts = widget.products.products
                              .where((product) => product.quantityMm <= AppConstants.lowStockThresholdMm)
                              .toList();
                          if (lowStockProducts.isEmpty) {
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  Translator.translate('all_products_healthy'),
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ),
                            );
                          }
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: lowStockProducts.map((product) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  border: Border.all(color: Colors.red.shade200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 16,
                                      color: Colors.red.shade700,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      product.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade800,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      formatMillimeters(product.quantityMm),
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      // ── Stock levels ──────────────────────────────────────
                      _SectionHeader(title: Translator.translate('product_stock_levels')),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: widget.products.products.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                            itemBuilder: (context, index) {
                              final product = widget.products.products.elementAt(index);
                              final isLow = product.quantityMm <= AppConstants.lowStockThresholdMm;
                              final isMedium = !isLow && product.quantityMm <= 200;
                              final progressColor = isLow
                                  ? Colors.red
                                  : isMedium
                                      ? Colors.orange
                                      : Colors.green;
                              final statusLabel = isLow
                                  ? Translator.translate('low')
                                  : isMedium
                                      ? Translator.translate('medium')
                                      : Translator.translate('healthy');
                              final statusTextColor = isLow
                                  ? Colors.red.shade700
                                  : isMedium
                                      ? Colors.orange.shade700
                                      : Colors.green.shade700;
                              final statusBgColor = isLow
                                  ? Colors.red.shade100
                                  : isMedium
                                      ? Colors.orange.shade100
                                      : Colors.green.shade100;
                              final progress = product.initialQuantityMm > 0
                                  ? (product.quantityMm / product.initialQuantityMm).clamp(0.0, 1.0)
                                  : 0.0;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    // Product name
                                    SizedBox(
                                      width: 110,
                                      child: Text(
                                        product.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Progress bar
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: Colors.grey.shade200,
                                          color: progressColor,
                                          minHeight: 8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Quantity + status badge
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: <Widget>[
                                        Text(
                                          formatMillimeters(product.quantityMm),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusBgColor,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            statusLabel,
                                            style: TextStyle(
                                              color: statusTextColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Best selling product ──────────────────────────────
                      _SectionHeader(title: Translator.translate('best_selling_product')),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: bestProduct == null
                              ? Text(
                                  Translator.translate('no_sales_in_range'),
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: const Color(0xFF5B635E),
                                      ),
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.emoji_events_outlined,
                                        color: Color(0xFFFFA000),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            bestProduct.productName,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(0xFF173531),
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${Translator.translate('sold_in_range')}: ${formatCurrency(filteredSales.where((sale) => sale.productId == bestProduct.productId).fold<double>(0, (sum, sale) => sum + sale.finalTotal))}',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: const Color(0xFF5B635E),
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${Translator.translate('quantity_in_mm')}: ${formatMillimeters(filteredSales.where((sale) => sale.productId == bestProduct.productId).fold<double>(0, (sum, sale) => sum + sale.quantityMm))}',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: const Color(0xFF5B635E),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

// ── Data holders (no logic, just named tuples for the grid builders) ──────────

class _StatCardData {
  const _StatCardData({
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
}

class _MiniCardData {
  const _MiniCardData({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

// ── Reusable layout widgets ───────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _DateContainer extends StatelessWidget {
  const _DateContainer({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.calendar_month_outlined, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF5B635E),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF5B635E),
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF173531),
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5B635E),
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: const Color(0xFF5B635E)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF5B635E),
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF173531),
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ImportResultDialog extends StatelessWidget {
  const _ImportResultDialog({required this.result});

  final ImportResult result;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(Translator.translate('import_complete')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!result.hasAnyNew && result.totalDuplicates == 0)
            Text(Translator.translate('import_no_new_data'))
          else ...<Widget>[
            Text(
              Translator.translate('import_summary_header'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5B635E),
                  ),
            ),
            const SizedBox(height: 12),
            _ResultRow(
              label: Translator.translate('products'),
              added: result.productsAdded,
              duplicates: result.productsDuplicate,
            ),
            _ResultRow(
              label: Translator.translate('sales_history'),
              added: result.salesAdded,
              duplicates: result.salesDuplicate,
            ),
            _ResultRow(
              label: Translator.translate('customers'),
              added: result.customersAdded,
              duplicates: result.customersDuplicate,
            ),
            _ResultRow(
              label: Translator.translate('finance'),
              added: result.expensesAdded,
              duplicates: result.expensesDuplicate,
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(Translator.translate('ok')),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.added,
    required this.duplicates,
  });

  final String label;
  final int added;
  final int duplicates;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '+$added',
            style: TextStyle(
              color: added > 0
                  ? Colors.green.shade700
                  : const Color(0xFF5B635E),
              fontWeight: FontWeight.bold,
            ),
          ),
          if (duplicates > 0) ...<Widget>[
            const SizedBox(width: 8),
            Text(
              Translator.translate('import_skipped', {'n': '$duplicates'}),
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
