import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../core/utils/translator.dart';
import '../state/customer_controller.dart';
import '../state/product_catalog_controller.dart';
import '../widgets/brand_mark.dart';
import 'add_product_page.dart';
import 'sell_product_page.dart';

class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({
    super.key,
    required this.catalog,
    required this.productId,
    required this.customers,
  });

  static const String routeName = '/product';

  final ProductCatalogController catalog;
  final String productId;
  final CustomerController customers;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: catalog,
      builder: (context, _) {
        final product = catalog.productById(productId);

        return Scaffold(
          appBar: AppBar(
            title: const BrandMark(showTagline: false),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            top: false,
            child: product == null
                ? const _ProductNotFound()
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 860),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: <Color>[
                                        Color(0xFF18534F),
                                        Color(0xFF2A7A6F),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    product.name.isNotEmpty
                                        ? product.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        product.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFF173531),
                                              letterSpacing: -0.3,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        Translator.translate(
                                          'product_details_description',
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: const Color(0xFF8D9490),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final crossAxisCount =
                                    constraints.maxWidth >= 600 ? 3 : 2;
                                final itemWidth =
                                    (constraints.maxWidth - (crossAxisCount - 1) * 12) /
                                        crossAxisCount;
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: <Widget>[
                                    _StatTile(
                                      width: itemWidth,
                                      label: Translator.translate(
                                        'bought_for_total_amount',
                                      ),
                                      value: formatCurrency(product.purchasePrice),
                                      icon: Icons.arrow_downward_rounded,
                                      color: const Color(0xFF2A7A6F),
                                      background: const Color(0xFFE6F2F0),
                                    ),
                                    _StatTile(
                                      width: itemWidth,
                                      label: Translator.translate(
                                        'sell_price_per_mm',
                                      ),
                                      value: formatCurrency(product.sellPrice),
                                      icon: Icons.arrow_upward_rounded,
                                      color: const Color(0xFF8A5A24),
                                      background: const Color(0xFFF5EDE0),
                                    ),
                                    _StatTile(
                                      width: itemWidth,
                                      label: Translator.translate(
                                        'remaining_stock_cost',
                                      ),
                                      value: formatCurrency(product.stockValue),
                                      icon: Icons.account_balance_outlined,
                                      color: const Color(0xFF3D6B8C),
                                      background: const Color(0xFFE3EEF5),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _StockCard(product: product),
                            const SizedBox(height: 16),
                            _ActionsCard(
                              product: product,
                              catalog: catalog,
                              customers: customers,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE5D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8D9490),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF173531),
                ),
          ),
        ],
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard({required this.product});

  final dynamic product;

  @override
  Widget build(BuildContext context) {
    final pct = (product.quantityMm as double) /
        (product.initialQuantityMm as double).clamp(1.0, double.infinity);
    final clamped = pct.clamp(0.0, 1.0);
    final Color barColor;
    if (clamped <= 0.15) {
      barColor = Colors.red.shade600;
    } else if (clamped <= 0.4) {
      barColor = Colors.orange.shade600;
    } else {
      barColor = const Color(0xFF18534F);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE5D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                Translator.translate('current_stock'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF173531),
                    ),
              ),
              Text(
                formatMillimeters(product.quantityMm as double),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: barColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 10,
              backgroundColor: const Color(0xFFEDE5D8),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFAAB2AE),
                    ),
              ),
              Text(
                formatMillimeters(product.initialQuantityMm as double),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFAAB2AE),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.product,
    required this.catalog,
    required this.customers,
  });

  final dynamic product;
  final ProductCatalogController catalog;
  final CustomerController customers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE5D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            Translator.translate('actions'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF173531),
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pushNamed(
                  SellProductPage.routeName,
                  arguments: product.id as String,
                ),
                icon: const Icon(Icons.sell_outlined, size: 18),
                label: Text(Translator.translate('sell_this_product')),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => AddProductPage(
                      catalog: catalog,
                      productId: product.id as String,
                    ),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(Translator.translate('edit_product')),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF7F2E9),
                  foregroundColor: const Color(0xFF173531),
                ),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(Translator.translate('delete_product')),
                      content: Text(
                        Translator.translate('product_delete_confirm'),
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(Translator.translate('back')),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child:
                              Text(Translator.translate('delete_product')),
                        ),
                      ],
                    ),
                  );

                  if (shouldDelete == true) {
                    catalog.removeProduct(product.id as String);
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          Translator.translate('product_deleted'),
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.delete_outlined, size: 18),
                label: Text(Translator.translate('delete_product')),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                ),
              ),
            ],
          ),
          if (customers.customers.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            Text(
              Translator.translate('special_customers_discount'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8D9490),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductNotFound extends StatelessWidget {
  const _ProductNotFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 36,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            Translator.translate('product_not_found'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF173531),
                ),
          ),
        ],
      ),
    );
  }
}
