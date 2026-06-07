class PackagingItem {
  const PackagingItem({
    required this.id,
    required this.sizeMl,
    required this.quantity,
    required this.createdAt,
  });

  factory PackagingItem.fromJson(Map<String, dynamic> json) {
    return PackagingItem(
      id: json['id'] as String,
      sizeMl: (json['sizeMl'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final double sizeMl;
  final int quantity;
  final DateTime createdAt;

  PackagingItem copyWith({double? sizeMl, int? quantity}) {
    return PackagingItem(
      id: id,
      sizeMl: sizeMl ?? this.sizeMl,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'sizeMl': sizeMl,
      'quantity': quantity,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
