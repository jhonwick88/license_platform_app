import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'product_model.dart';

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/admin/products');
  final data = response.data['data'] as List;
  return data.map((e) => Product.fromJson(e)).toList();
});

class ProductNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  ProductNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<bool> createProduct(String code, String name, String description) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/admin/products', data: {
        'product_code': code,
        'name': name,
        'description': description,
      });
      ref.invalidate(productsProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final productActionProvider = StateNotifierProvider<ProductNotifier, AsyncValue<void>>((ref) {
  return ProductNotifier(ref);
});
