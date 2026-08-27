class Feature {
  final String id;
  final String productId;
  final String code;
  final String name;
  final String? description;
  final String dataType;

  Feature({
    required this.id, 
    required this.productId, 
    required this.code, 
    required this.name, 
    this.description,
    required this.dataType
  });

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      dataType: json['data_type'] ?? '',
    );
  }
}
