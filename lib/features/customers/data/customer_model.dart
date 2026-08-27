class Customer {
  final String id;
  final String name;
  final String email;
  final String? company;
  final String? phone;
  final String status;
  final List<dynamic>? licenses;

  Customer({
    required this.id, 
    required this.name, 
    required this.email, 
    this.company, 
    this.phone, 
    required this.status,
    this.licenses,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      company: json['company_name'],
      phone: json['phone'],
      status: json['status'] ?? '',
      licenses: json['licenses'] as List<dynamic>?,
    );
  }
}

