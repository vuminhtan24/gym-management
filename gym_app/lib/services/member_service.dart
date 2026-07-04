import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_constants.dart';
import '../models/member.dart';
import '../models/subscription.dart';

class MemberService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<Member>> list({String? search, String? statusFilter}) async {
    final response = await _dio.get(
      ApiConstants.members,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (statusFilter != null) 'status': statusFilter,
        'limit': 200,
      },
    );
    return (response.data as List)
        .map((e) => Member.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Member> create(Member member) async {
    final response = await _dio.post(ApiConstants.members, data: member.toCreateJson());
    return Member.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Member> update(int id, Member member) async {
    final response = await _dio.put(ApiConstants.memberDetail(id), data: member.toUpdateJson());
    return Member.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _dio.delete(ApiConstants.memberDetail(id));
  }

  Future<List<Subscription>> getSubscriptions(int memberId) async {
    final response = await _dio.get(ApiConstants.memberSubscriptions(memberId));
    return (response.data as List)
        .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
