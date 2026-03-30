class SaleRecord {
  const SaleRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantityMm,
    required this.unitPrice,
    required this.discountPercent,
    required this.subtotal,
    required this.finalTotal,
    required this.soldAt,
    this.customerId,
    this.customerName,
  });

  factory SaleRecord.fromJson(Map<String, dynamic> json) {
    return SaleRecord(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantityMm: (json['quantityMm'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      discountPercent: (json['discountPercent'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      finalTotal: (json['finalTotal'] as num).toDouble(),
      soldAt: DateTime.parse(json['soldAt'] as String),
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String?,
    );
  }

  final String id;
  final String productId;
  final String productName;
  final double quantityMm;
  final double unitPrice;
  final double discountPercent;
  final double subtotal;
  final double finalTotal;
  final DateTime soldAt;
  final String? customerId;
  final String? customerName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantityMm': quantityMm,
      'unitPrice': unitPrice,
      'discountPercent': discountPercent,
      'subtotal': subtotal,
      'finalTotal': finalTotal,
      'soldAt': soldAt.toIso8601String(),
      'customerId': customerId,
      'customerName': customerName,
    };
  }
}
