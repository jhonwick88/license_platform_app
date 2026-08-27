class PlanFeature {
  final String featureId;
  final String value;
  final Map<String, dynamic>? feature;

  PlanFeature({required this.featureId, required this.value, this.feature});

  factory PlanFeature.fromJson(Map<String, dynamic> json) {
    return PlanFeature(
      featureId: json['feature_id'],
      value: json['value'],
      feature: json['feature'],
    );
  }
}

class Plan {
  final String id;
  final String productId;
  final String code;
  final String name;
  final String? description;
  final String status;
  final Map<String, dynamic>? product;
  final List<PlanFeature>? planFeatures;

  Plan({
    required this.id,
    required this.productId,
    required this.code,
    required this.name,
    this.description,
    required this.status,
    this.product,
    this.planFeatures,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    var pFeaturesRaw = json['plan_features'] as List?;
    List<PlanFeature>? pFeatures;
    if (pFeaturesRaw != null) {
      pFeatures = pFeaturesRaw.map((e) => PlanFeature.fromJson(e)).toList();
    }

    return Plan(
      id: json['id'],
      productId: json['product_id'],
      code: json['code'],
      name: json['name'],
      description: json['description'],
      status: json['status'] ?? 'ACTIVE',
      product: json['product'],
      planFeatures: pFeatures,
    );
  }
}
