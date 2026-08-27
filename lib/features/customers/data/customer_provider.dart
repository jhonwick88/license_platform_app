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

  Future<bool> createCustomer(String code, String name, String email, String phone, String address, String companyName) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/admin/customers', data: {
        'customer_code': code,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'company_name': companyName,
      });
      ref.invalidate(customersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateCustomer(String id, String name, String email, String phone, String address, String companyName) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      await dio.put('/admin/customers/$id', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'company_name': companyName,
      });
      ref.invalidate(customersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/admin/customers/$id');
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
