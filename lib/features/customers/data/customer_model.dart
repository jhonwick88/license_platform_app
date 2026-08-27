class Customer {
  final String id;
  final String customerCode;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String status;

  Customer({
    required this.id,
    required this.customerCode,
    required this.name,
    this.email,
    this.phone,
    this.address,
    required this.status,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      customerCode: json['customer_code'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      status: json['status'] ?? 'ACTIVE',
    );
  }
}
