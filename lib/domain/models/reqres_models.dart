import 'user_model.dart';

class ReqresUsersPage {
  const ReqresUsersPage({
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
    required this.users,
  });

  final int page;
  final int perPage;
  final int total;
  final int totalPages;
  final List<UserModel> users;

  factory ReqresUsersPage.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => UserModel.fromReqres(e.cast<String, dynamic>()))
        .toList();
    return ReqresUsersPage(
      page: json['page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? data.length,
      total: json['total'] as int? ?? data.length,
      totalPages: json['total_pages'] as int? ?? 1,
      users: data,
    );
  }
}

class ReqresCreateUserResponse {
  const ReqresCreateUserResponse({
    required this.idRaw,
    required this.createdAt,
  });

  final String idRaw;
  final String createdAt;

  int? get parsedId => int.tryParse(idRaw);

  factory ReqresCreateUserResponse.fromJson(Map<String, dynamic> json) {
    return ReqresCreateUserResponse(
      idRaw: '${json['id'] ?? ''}',
      createdAt: '${json['createdAt'] ?? ''}',
    );
  }
}
