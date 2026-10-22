/// Thrown by data sources. Repositories turn them into failures.
class ServerException implements Exception {
  const ServerException();
}

class NotFoundException implements Exception {
  const NotFoundException();
}

class CacheException implements Exception {
  const CacheException();
}
