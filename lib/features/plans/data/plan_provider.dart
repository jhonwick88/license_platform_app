import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'plan_model.dart';

final plansProvider = FutureProvider<List<Plan>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/admin/plans');
  final data = response.data['data'] as List;
  return data.map((e) => Plan.fromJson(e)).toList();
});

class PlanNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  PlanNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<bool> createPlan(String productId, String code, String name, String description, List<Map<String, String>> features) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/admin/plans', data: {
        'product_id': productId,
        'code': code,
        'name': name,
        'description': description,
        'features': features,
      });
      ref.invalidate(plansProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final planActionProvider = StateNotifierProvider<PlanNotifier, AsyncValue<void>>((ref) {
  return PlanNotifier(ref);
});
