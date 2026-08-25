class Plan {
  final String id;
  final String productId;
  final String code;
  final String name;
  final String? description;
  final String status;

  Plan({
    required this.id,
    required this.productId,
    required this.code,
    required this.name,
    this.description,
    required this.status,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'],
      productId: json['product_id'],
      code: json['code'],
      name: json['name'],
      description: json['description'],
      status: json['status'] ?? 'ACTIVE',
    );
  }
}
