class Customer {
  const Customer({
    required this.id,
    required this.customerId,
    required this.name,
    required this.phone,
    required this.discountPercent,
    required this.notes,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      discountPercent: (json['discountPercent'] as num).toDouble(),
      notes: json['notes'] as String,
    );
  }

  final String id;
  final String customerId;
  final String name;
  final String phone;
  final double discountPercent;
  final String notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'customerId': customerId,
      'name': name,
      'phone': phone,
      'discountPercent': discountPercent,
      'notes': notes,
    };
  }

  Customer copyWith({
    String? id,
    String? customerId,
    String? name,
    String? phone,
    double? discountPercent,
    String? notes,
  }) {
    return Customer(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      discountPercent: discountPercent ?? this.discountPercent,
      notes: notes ?? this.notes,
    );
  }

  bool matches(String normalizedQuery) {
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final searchableText = '$customerId $name $phone $notes'.toLowerCase();
    return searchableText.contains(normalizedQuery);
  }
}
