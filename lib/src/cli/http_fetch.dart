import 'dart:convert';
import 'dart:io';

/// The parts of an HTTP response the doctor looks at.
class FetchedFile {
  /// Creates a response summary.
  const FetchedFile({
    required this.status,
    required this.body,
    this.contentType,
    this.location,
  });

  /// The HTTP status code.
  final int status;

  /// The response body as text.
  final String body;

  /// The MIME type, e.g. `application/json`.
  final String? contentType;

  /// The `Location` header of a redirect.
  final String? location;

  /// Whether the server answered with a redirect.
  bool get isRedirect => status >= 300 && status < 400;
}

/// Fetches a URL without following redirects. Replaced in tests.
typedef Fetcher = Future<FetchedFile> Function(Uri uri);

/// The real [Fetcher], using `dart:io`. Redirects are reported, not followed,
/// because Android and Apple reject verification files behind redirects.
Future<FetchedFile> fetchWithoutRedirects(Uri uri) async {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15)
    ..userAgent = 'deep_links_kit doctor';
  try {
    final request = await client.getUrl(uri);
    request.followRedirects = false;
    final response = await request.close().timeout(
          const Duration(seconds: 20),
        );
    final body = await response.transform(utf8.decoder).join();
    return FetchedFile(
      status: response.statusCode,
      body: body,
      contentType: response.headers.contentType?.mimeType,
      location: response.headers.value(HttpHeaders.locationHeader),
    );
  } finally {
    client.close(force: true);
  }
}
