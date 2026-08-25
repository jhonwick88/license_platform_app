import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'customer_model.dart';

final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/admin/customers');
  final data = response.data['data'] as List;
  return data.map((e) => Customer.fromJson(e)).toList();
});

class CustomerNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  CustomerNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<bool> createCustomer(String code, String name, String email) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/admin/customers', data: {
        'customer_code': code,
        'name': name,
        'email': email,
      });
      ref.invalidate(customersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final customerActionProvider = StateNotifierProvider<CustomerNotifier, AsyncValue<void>>((ref) {
  return CustomerNotifier(ref);
});
