class Product {
  const Product({
    required this.id,
    required this.name,
    required this.purchasePrice,
    required this.sellPrice,
    required this.quantityMm,
    required this.initialQuantityMm,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final quantityMm = (json['quantityMm'] as num).toDouble();
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      sellPrice: (json['sellPrice'] as num).toDouble(),
      quantityMm: quantityMm,
      initialQuantityMm: ((json['initialQuantityMm'] as num?) ?? quantityMm)
          .toDouble(),
    );
  }

  final String id;
  final String name;
  final double purchasePrice;
  final double sellPrice;
  final double quantityMm;
  final double initialQuantityMm;

  double get stockValue {
    if (initialQuantityMm <= 0) {
      return purchasePrice;
    }
    return purchasePrice * (quantityMm / initialQuantityMm);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'purchasePrice': purchasePrice,
      'sellPrice': sellPrice,
      'quantityMm': quantityMm,
      'initialQuantityMm': initialQuantityMm,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    double? purchasePrice,
    double? sellPrice,
    double? quantityMm,
    double? initialQuantityMm,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellPrice: sellPrice ?? this.sellPrice,
      quantityMm: quantityMm ?? this.quantityMm,
      initialQuantityMm: initialQuantityMm ?? this.initialQuantityMm,
    );
  }

  bool matches(String normalizedQuery) {
    if (normalizedQuery.isEmpty) {
      return true;
    }

    return name.toLowerCase().contains(normalizedQuery);
  }
}
