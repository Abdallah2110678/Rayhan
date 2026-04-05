import 'package:flutter/material.dart';

import '../core/utils/formatters.dart';
import '../core/utils/translator.dart';
import '../models/product.dart';
import '../state/product_catalog_controller.dart';
import '../widgets/page_header.dart';
import '../widgets/product_card.dart';
import 'product_details_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, required this.catalog});

  final ProductCatalogController catalog;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetails(Product product) {
    Navigator.of(context).pushNamed(
      ProductDetailsPage.routeName,
      arguments: product.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.catalog,
      builder: (context, _) {
        final products = widget.catalog.search(_query);
        final hasProducts = widget.catalog.products.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              PageHeader(
                title: Translator.translate('all_products_page_title'),
                subtitle: Translator.translate('all_products_page_subtitle'),
                trailing: _OverviewPill(
                  label: Translator.translate('products_overview'),
                  value: formatMillimeters(widget.catalog.totalQuantityMm),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: Translator.translate('search_products'),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: !hasProducts
                    ? _EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: Translator.translate('no_products_yet'),
                        description: Translator.translate(
                          'no_products_yet_description',
                        ),
                      )
                    : products.isEmpty
                    ? _EmptyState(
                            icon: Icons.search_off,
                        title: Translator.translate('no_matching_products'),
                        description: Translator.translate(
                          'no_matching_products_description',
                        ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = constraints.maxWidth >= 1200
                                  ? 3
                                  : constraints.maxWidth >= 760
                                      ? 2
                                      : 1;

                              return GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 18,
                                  mainAxisSpacing: 18,
                                  childAspectRatio:
                                      crossAxisCount == 1 ? 1.55 : 1.08,
                                ),
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  final product = products[index];
                                  return ProductCard(
                                    product: product,
                                    onOpen: () => _openDetails(product),
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewPill extends StatelessWidget {
  const _OverviewPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7DDCF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF67706B),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE6EFE8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 34, color: const Color(0xFF18534F)),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF173531),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF5A625D),
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
