class Customer {
  final String id;
  final String customerCode;
  final String name;
  final String? email;
  final String status;

  Customer({
    required this.id,
    required this.customerCode,
    required this.name,
    this.email,
    required this.status,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      customerCode: json['customer_code'],
      name: json['name'],
      email: json['email'],
      status: json['status'] ?? 'ACTIVE',
    );
  }
}
