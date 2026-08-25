class Feature {
  final String id;
  final String productId;
  final String code;
  final String name;
  final String dataType;

  Feature({required this.id, required this.productId, required this.code, required this.name, required this.dataType});

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      dataType: json['data_type'] ?? '',
    );
  }
}
