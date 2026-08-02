abstract interface class HttpClientStatus {
  bool isError(int statusCode);
  bool isSuccess(int statusCode);
  bool isRateLimit(int statusCode);
}

/// Classifies HTTP statuses by range rather than by an enumerated allowlist.
///
/// [isSuccess] and [isRateLimit] partition off the two ranges the framework
/// treats specially; [isError] is the complement of both, so it always
/// covers the rest of the space (1xx/3xx, undocumented codes, anything
/// Discord adds in the future) instead of requiring every new status to be
/// hand-added to a list. Without this, an unclassified status (Discord
/// documents 304, and returns 409/413/501) fails every check and a caller
/// looping on classification results can silently re-issue the request
/// forever.
final class HttpClientStatusImpl implements HttpClientStatus {
  @override
  bool isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  @override
  bool isRateLimit(int statusCode) => statusCode == 429;

  @override
  bool isError(int statusCode) =>
      !isSuccess(statusCode) && !isRateLimit(statusCode);
}
