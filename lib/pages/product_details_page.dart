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
          appBar: AppBar(title: const BrandMark(showTagline: false)),
          body: SafeArea(
            top: false,
            child: product == null
                ? const _ProductNotFound()
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              product.name,
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF173531),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              Translator.translate(
                                'product_details_description',
                              ),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: const Color(0xFF5A625D),
                                  ),
                            ),
                            const SizedBox(height: 24),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(22),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: <Widget>[
                                    _MetaTile(
                                      label: Translator.translate('name_label'),
                                      value: product.name,
                                    ),
                                    _MetaTile(
                                      label: Translator.translate(
                                        'bought_for_total_amount',
                                      ),
                                      value: formatCurrency(product.purchasePrice),
                                    ),
                                    _MetaTile(
                                      label: Translator.translate(
                                        'sell_price_per_mm',
                                      ),
                                      value: formatCurrency(product.sellPrice),
                                    ),
                                    _MetaTile(
                                      label: Translator.translate(
                                        'quantity_in_mm',
                                      ),
                                      value: formatMillimeters(product.quantityMm),
                                    ),
                                    _MetaTile(
                                      label: Translator.translate(
                                        'remaining_stock_cost',
                                      ),
                                      value: formatCurrency(product.stockValue),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      Translator.translate('actions'),
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF173531),
                                          ),
                                    ),
                                    const SizedBox(height: 20),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: <Widget>[
                                        FilledButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).pushNamed(
                                              SellProductPage.routeName,
                                              arguments: product.id,
                                            );
                                          },
                                          icon: const Icon(Icons.sell_outlined),
                                          label: Text(
                                            Translator.translate(
                                              'sell_this_product',
                                            ),
                                          ),
                                        ),
                                        FilledButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (context) =>
                                                    AddProductPage(
                                                      catalog: catalog,
                                                      productId: product.id,
                                                    ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.edit_outlined),
                                          label: Text(
                                            Translator.translate(
                                              'edit_product',
                                            ),
                                          ),
                                        ),
                                        FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                Colors.red.shade700,
                                          ),
                                          onPressed: () async {
                                            final shouldDelete =
                                                await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: Text(
                                                      Translator.translate(
                                                        'delete_product',
                                                      ),
                                                    ),
                                                    content: Text(
                                                      Translator.translate(
                                                        'product_delete_confirm',
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                              context,
                                                            ).pop(false),
                                                        child: Text(
                                                          Translator.translate(
                                                            'back',
                                                          ),
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                              context,
                                                            ).pop(true),
                                                        child: Text(
                                                          Translator.translate(
                                                            'delete_product',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                            if (shouldDelete == true) {
                                              catalog.removeProduct(product.id);
                                              Navigator.of(context).pop();
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    Translator.translate(
                                                      'product_deleted',
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.delete_outlined,
                                          ),
                                          label: Text(
                                            Translator.translate(
                                              'delete_product',
                                            ),
                                          ),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () => Navigator.of(context).pop(),
                                          icon: const Icon(Icons.arrow_back),
                                          label: Text(
                                            Translator.translate('back'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (customers.customers.isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 16),
                                      Text(
                                        Translator.translate(
                                          'special_customers_discount',
                                        ),
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: const Color(0xFF5A625D),
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
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

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5DCCF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label),
          const SizedBox(height: 6),
          Text(
            value,
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

class _ProductNotFound extends StatelessWidget {
  const _ProductNotFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.warning_amber_rounded, size: 42),
              const SizedBox(height: 12),
              Text(
                'This product no longer exists.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
