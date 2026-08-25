import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'feature_model.dart';

final featuresProvider = FutureProvider<List<Feature>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/admin/features');
  final data = response.data['data'] as List;
  return data.map((e) => Feature.fromJson(e)).toList();
});
