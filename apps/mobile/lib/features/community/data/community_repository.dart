import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';
import '../../../app/di.dart';

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => CommunityRepository(ref.read(supabaseClientProvider)),
);

class CommunityRepository {
  CommunityRepository(this._client);
  final dynamic _client;

  Future<List<Discussion>> fetchDiscussions() async {
    final response = await _client
        .from('discussions')
        .select()
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => Discussion.fromJson(_map(e as Map<String, dynamic>)))
        .toList();
  }

  Map<String, dynamic> _map(Map<String, dynamic> json) {
    return {
      'id': json['id'] as String,
      'courseId': json['course_id'] as String,
      'userId': json['user_id'] as String,
      'title': json['title'] as String,
      'body': json['body'] as String,
      'createdAt': DateTime.parse(json['created_at'] as String),
    };
  }
}

