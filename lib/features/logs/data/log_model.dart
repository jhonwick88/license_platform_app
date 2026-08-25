class AuditLog {
  final String id;
  final String licenseId;
  final String installationId;
  final String? ipAddress;
  final bool isValid;
  final String? failureReason;

  AuditLog({
    required this.id,
    required this.licenseId,
    required this.installationId,
    this.ipAddress,
    required this.isValid,
    this.failureReason,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      licenseId: json['license_id'],
      installationId: json['installation_id'],
      ipAddress: json['ip_address'],
      isValid: json['is_valid'] ?? false,
      failureReason: json['failure_reason'],
    );
  }
}
