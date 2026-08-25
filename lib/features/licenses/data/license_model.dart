class License {
  final String id;
  final String licenseKey;
  final String customerId;
  final String productId;
  final String planId;
  final String status;
  final String? installationId;

  License({
    required this.id,
    required this.licenseKey,
    required this.customerId,
    required this.productId,
    required this.planId,
    required this.status,
    this.installationId,
  });

  factory License.fromJson(Map<String, dynamic> json) {
    return License(
      id: json['id'],
      licenseKey: json['license_key'],
      customerId: json['customer_id'],
      productId: json['product_id'],
      planId: json['plan_id'],
      status: json['status'],
      installationId: json['installation_id'],
    );
  }
}
