class MovieModel {
  const MovieModel({
    required this.id,
    this.imdbId,
    required this.title,
    this.overview,
    this.releaseDate,
    this.posterPath,
  });

  final int id;
  final String? imdbId;
  final String title;
  final String? overview;
  final String? releaseDate;
  final String? posterPath;

  static int idFromImdb(String imdbId) {
    return imdbId.hashCode.abs() & 0x7fffffff;
  }

  factory MovieModel.fromOmdbList(Map<String, dynamic> json) {
    final imdbId = json['imdbID'] as String? ?? '';
    final poster = json['Poster'] as String?;
    return MovieModel(
      id: idFromImdb(imdbId),
      imdbId: imdbId,
      title: '${json['Title'] ?? ''}',
      overview: 'Tap to load full description.',
      releaseDate: json['Year'] as String?,
      posterPath: poster == null || poster == 'N/A' ? null : poster,
    );
  }

  factory MovieModel.fromOmdbDetail({
    required Map<String, dynamic> json,
    required int id,
    String? fallbackTitle,
    String? fallbackOverview,
    String? fallbackReleaseDate,
    String? fallbackPosterPath,
    String? fallbackImdbId,
  }) {
    final poster = json['Poster'] as String?;
    return MovieModel(
      id: id,
      imdbId: (json['imdbID'] as String?) ?? fallbackImdbId,
      title: '${json['Title'] ?? fallbackTitle ?? ''}',
      overview: (json['Plot'] as String?) ?? fallbackOverview,
      releaseDate: (json['Released'] as String?) ?? fallbackReleaseDate,
      posterPath: poster == null || poster == 'N/A' ? fallbackPosterPath : poster,
    );
  }

  factory MovieModel.fromDb(Map<String, dynamic> row) {
    return MovieModel(
      id: row['id'] as int,
      imdbId: row['imdb_id'] as String?,
      title: '${row['title'] ?? ''}',
      overview: row['overview'] as String?,
      releaseDate: row['release_date'] as String?,
      posterPath: row['poster_path'] as String?,
    );
  }

  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'imdb_id': imdbId,
      'title': title,
      'overview': overview,
      'release_date': releaseDate,
      'poster_path': posterPath,
    };
  }
}
