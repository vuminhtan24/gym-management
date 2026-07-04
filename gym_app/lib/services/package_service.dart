import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_constants.dart';
import '../models/package.dart';
import '../models/subscription.dart';

class PackageService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<GymPackage>> list({bool onlyActive = false}) async {
    final response = await _dio.get(
      ApiConstants.packages,
      queryParameters: {'only_active': onlyActive},
    );
    return (response.data as List)
        .map((e) => GymPackage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GymPackage> create(GymPackage pkg) async {
    final response = await _dio.post(ApiConstants.packages, data: pkg.toCreateJson());
    return GymPackage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GymPackage> update(int id, GymPackage pkg) async {
    final response = await _dio.put(ApiConstants.packageDetail(id), data: pkg.toUpdateJson());
    return GymPackage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _dio.delete(ApiConstants.packageDetail(id));
  }

  /// Đăng ký gói tập cho một thành viên.
  Future<Subscription> createSubscription({
    required int memberId,
    required int packageId,
    required DateTime startDate,
    double? pricePaid,
  }) async {
    final response = await _dio.post(
      ApiConstants.subscriptions,
      data: {
        'member_id': memberId,
        'package_id': packageId,
        'start_date':
            '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
        if (pricePaid != null) 'price_paid': pricePaid,
      },
    );
    return Subscription.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSubscription(int id) async {
    await _dio.delete(ApiConstants.subscriptionDetail(id));
  }
}
