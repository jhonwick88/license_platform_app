import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'installation_model.dart';

final installationsProvider = FutureProvider<List<Installation>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/admin/installations');
  final data = response.data['data'] as List;
  return data.map((e) => Installation.fromJson(e)).toList();
});
