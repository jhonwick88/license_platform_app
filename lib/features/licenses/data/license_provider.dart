import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../installations/data/installation_provider.dart';
import '../../customers/data/customer_provider.dart';
import '../../../core/network/api_client.dart';
import 'license_model.dart';

final licensesProvider = FutureProvider.autoDispose<List<License>>((ref) async {
  // Polling every 3 seconds to auto-refresh license status
  final timer = Timer(const Duration(seconds: 3), () {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  final dio = ref.read(dioProvider);
  final response = await dio.get('/admin/licenses');
  final data = response.data['data'] as List;
  return data.map((e) => License.fromJson(e)).toList();
});

class LicenseNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  LicenseNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<bool> createLicense(String customerId, String productId, String planId) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/admin/licenses', data: {
        'customer_id': customerId,
        'product_id': productId,
        'plan_id': planId,
      });
      ref.invalidate(licensesProvider);
      ref.invalidate(installationsProvider);
      ref.invalidate(customersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> changeStatus(String id, String action) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/admin/licenses/$id/$action');
      ref.invalidate(licensesProvider);
      ref.invalidate(installationsProvider);
      ref.invalidate(customersProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unbindLicense(String id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/admin/licenses/$id/unbind');
      ref.invalidate(licensesProvider);
      ref.invalidate(installationsProvider);
      ref.invalidate(customersProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteLicense(String id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/admin/licenses/$id');
      ref.invalidate(licensesProvider);
      ref.invalidate(installationsProvider);
      ref.invalidate(customersProvider);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final licenseActionProvider = StateNotifierProvider<LicenseNotifier, AsyncValue<void>>((ref) {
  return LicenseNotifier(ref);
});


