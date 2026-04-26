class Env {
  static const reqresApiKey = String.fromEnvironment(
    'REQRES_API_KEY',
    defaultValue: 'free_user_3CtLd6zJf9eOMO2YyPbnOfREiPY',
  );
  static const omdbApiKey = String.fromEnvironment(
    'OMDB_API_KEY',
    defaultValue: '78eaba29',
  );
}
