class License {
  final String id;
  final String licenseKey;
  final String customerId;
  final String productId;
  final String planId;
  final String? installationId;
  final String status;
  final DateTime? activatedAt;
  final DateTime? lastValidationAt;
  final DateTime createdAt;

  final Map<String, dynamic>? product;
  final Map<String, dynamic>? plan;
  final Map<String, dynamic>? customer;

  License({
    required this.id,
    required this.licenseKey,
    required this.customerId,
    required this.productId,
    required this.planId,
    this.installationId,
    required this.status,
    this.activatedAt,
    this.lastValidationAt,
    required this.createdAt,
    this.product,
    this.plan,
    this.customer,
  });

  factory License.fromJson(Map<String, dynamic> json) {
    return License(
      id: json['id'] ?? '',
      licenseKey: json['license_key'] ?? '',
      customerId: json['customer_id'] ?? '',
      productId: json['product_id'] ?? '',
      planId: json['plan_id'] ?? '',
      installationId: json['installation_id'],
      status: json['status'] ?? 'PENDING',
      activatedAt: json['activated_at'] != null ? DateTime.parse(json['activated_at']) : null,
      lastValidationAt: json['last_validation_at'] != null ? DateTime.parse(json['last_validation_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      product: json['product'],
      plan: json['plan'],
      customer: json['customer'],
    );
  }
}
