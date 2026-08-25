import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'log_model.dart';

final logsProvider = FutureProvider<List<AuditLog>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/admin/logs');
  final data = response.data['data'] as List;
  return data.map((e) => AuditLog.fromJson(e)).toList();
});
