class Installation {
  final String id;
  final String licenseId;
  final String installationId;
  final String machineFingerprint;
  final String? platform;
  final String? hostname;
  final String? appVersion;
  final String status;

  Installation({
    required this.id,
    required this.licenseId,
    required this.installationId,
    required this.machineFingerprint,
    this.platform,
    this.hostname,
    this.appVersion,
    required this.status,
  });

  factory Installation.fromJson(Map<String, dynamic> json) {
    return Installation(
      id: json['id'],
      licenseId: json['license_id'],
      installationId: json['installation_id'],
      machineFingerprint: json['machine_fingerprint'],
      platform: json['platform'],
      hostname: json['hostname'],
      appVersion: json['app_version'],
      status: json['status'] ?? 'ACTIVE',
    );
  }
}
