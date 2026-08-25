class Product {
  final String id;
  final String productCode;
  final String name;
  final String? description;
  final String status;

  Product({
    required this.id,
    required this.productCode,
    required this.name,
    this.description,
    required this.status,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      productCode: json['product_code'],
      name: json['name'],
      description: json['description'],
      status: json['status'] ?? 'ACTIVE',
    );
  }
}
