import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'feature_model.dart';

final featuresProvider = FutureProvider<List<Feature>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/admin/features');
  final data = response.data['data'] as List;
  return data.map((e) => Feature.fromJson(e)).toList();
});

class FeatureNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  FeatureNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<bool> createFeature(String productId, String code, String name, String description, String dataType) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/admin/features', data: {
        'product_id': productId,
        'code': code,
        'name': name,
        'description': description,
        'data_type': dataType,
      });
      ref.invalidate(featuresProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateFeature(String id, String name, String description, String dataType) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      await dio.put('/admin/features/$id', data: {
        'name': name,
        'description': description,
        'data_type': dataType,
      });
      ref.invalidate(featuresProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteFeature(String id) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/admin/features/$id');
      ref.invalidate(featuresProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final featureActionProvider = StateNotifierProvider<FeatureNotifier, AsyncValue<void>>((ref) {
  return FeatureNotifier(ref);
});
