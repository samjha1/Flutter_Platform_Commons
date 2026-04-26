class UserModel {
  const UserModel({
    this.localId,
    this.serverId,
    required this.firstName,
    required this.lastName,
    required this.movieTaste,
    this.avatar,
    required this.pendingSync,
    this.savedCount = 0,
  });

  final int? localId;
  final int? serverId;
  final String firstName;
  final String lastName;
  final String movieTaste;
  final String? avatar;
  final bool pendingSync;
  final int savedCount;

  String get fullName => '$firstName $lastName'.trim();

  factory UserModel.fromReqres(Map<String, dynamic> json) {
    return UserModel(
      serverId: json['id'] as int?,
      firstName: '${json['first_name'] ?? ''}',
      lastName: '${json['last_name'] ?? ''}',
      movieTaste: 'No preference added',
      avatar: json['avatar'] as String?,
      pendingSync: false,
    );
  }

  factory UserModel.fromDb(Map<String, dynamic> row) {
    return UserModel(
      localId: row['local_id'] as int?,
      serverId: row['server_id'] as int?,
      firstName: '${row['first_name'] ?? ''}',
      lastName: '${row['last_name'] ?? ''}',
      movieTaste: '${row['movie_taste'] ?? ''}',
      avatar: row['avatar'] as String?,
      pendingSync: (row['pending_sync'] as int? ?? 0) == 1,
      savedCount: row['saved_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toDb() {
    return {
      'server_id': serverId,
      'first_name': firstName,
      'last_name': lastName,
      'movie_taste': movieTaste,
      'avatar': avatar,
      'pending_sync': pendingSync ? 1 : 0,
    };
  }
}
