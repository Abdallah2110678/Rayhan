enum PackagingType { bottle, box }

class PackagingItem {
  const PackagingItem({
    required this.id,
    required this.sizeMl,
    required this.quantity,
    required this.createdAt,
    this.type = PackagingType.bottle,
  });

  factory PackagingItem.fromJson(Map<String, dynamic> json) {
    return PackagingItem(
      id: json['id'] as String,
      sizeMl: (json['sizeMl'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      type: json['type'] == 'box' ? PackagingType.box : PackagingType.bottle,
    );
  }

  final String id;
  final double sizeMl;
  final int quantity;
  final DateTime createdAt;
  final PackagingType type;

  PackagingItem copyWith({double? sizeMl, int? quantity, PackagingType? type}) {
    return PackagingItem(
      id: id,
      sizeMl: sizeMl ?? this.sizeMl,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'sizeMl': sizeMl,
      'quantity': quantity,
      'createdAt': createdAt.toIso8601String(),
      'type': type == PackagingType.box ? 'box' : 'bottle',
    };
  }
}
