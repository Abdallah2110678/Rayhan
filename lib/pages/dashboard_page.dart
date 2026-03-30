import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../services/report_exporter.dart';
import '../state/customer_controller.dart';
import '../state/product_catalog_controller.dart';
import '../widgets/page_header.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.products,
    required this.customers,
  });

  final ProductCatalogController products;
  final CustomerController customers;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ReportExporter _reportExporter = ReportExporter();

  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isExporting = false;

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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[widget.products, widget.customers]),
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
              const PageHeader(
                title: 'Home statistics',
                subtitle:
                    'Track stock, filter sales by date, and generate a PDF report for the selected period.',
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
                                label: 'From',
                                value: formatDateOnly(from),
                                onTap: _pickFromDate,
                              ),
                              _DateChip(
                                label: 'To',
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
                                label: Text(_isExporting ? 'Generating...' : 'Generate PDF report'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: <Widget>[
                          _StatCard(
                            title: 'Total bought',
                            value: formatCurrency(widget.products.totalPurchaseValue),
                            note: formatMillimeters(widget.products.totalPurchasedQuantityMm),
                            color: const Color(0xFF8A5A24),
                            icon: Icons.shopping_bag_outlined,
                          ),
                          _StatCard(
                            title: 'Sold in range',
                            value: formatCurrency(filteredSalesValue),
                            note: formatMillimeters(filteredSoldQuantity),
                            color: const Color(0xFF18534F),
                            icon: Icons.point_of_sale_outlined,
                          ),
                          _StatCard(
                            title: 'Sales count',
                            value: '${filteredSales.length}',
                            note: '${formatDateOnly(from)} to ${formatDateOnly(to)}',
                            color: const Color(0xFF316B83),
                            icon: Icons.filter_alt_outlined,
                          ),
                          _StatCard(
                            title: 'Inventory value',
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
                            label: 'Products',
                            value: '${widget.products.productCount}',
                            icon: Icons.category_outlined,
                          ),
                          _MiniCard(
                            label: 'Customers',
                            value: '${widget.customers.customerCount}',
                            icon: Icons.groups_2_outlined,
                          ),
                          _MiniCard(
                            label: 'All-time sold',
                            value: formatMillimeters(widget.products.totalSoldQuantityMm),
                            icon: Icons.straighten,
                          ),
                          _MiniCard(
                            label: 'Remaining stock',
                            value: formatMillimeters(widget.products.totalQuantityMm),
                            icon: Icons.warehouse_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Best selling product in selected period',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                bestProduct == null
                                    ? 'No sales found in this date range.'
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
