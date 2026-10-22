abstract interface class SessionLocalDataSource {
  /// Throws a `CacheException` when the saved data cannot be read.
  Future<void> loadSession();
}

class SessionLocalDataSourceImpl implements SessionLocalDataSource {
  @override
  Future<void> loadSession() async {
    // Read the token, settings, etc. from storage.
    await Future<void>.delayed(const Duration(seconds: 2));
  }
}
