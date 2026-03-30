class CustomerDraft {
  const CustomerDraft({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.discountPercent,
    required this.notes,
  });

  final String customerId;
  final String name;
  final String phone;
  final double discountPercent;
  final String notes;
}
