class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.purchasePrice,
    required this.sellPrice,
    required this.quantityMm,
  });

  final String name;
  final double purchasePrice;
  final double sellPrice;
  final double quantityMm;
}
