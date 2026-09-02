/// Wraps data returned by a repository method that supports offline
/// fallback, so the provider (and ultimately the screen) can tell whether
/// what it got was live from the network or the last known-good copy from
/// disk.
class CachedResult<T> {
  CachedResult.live(this.data) : fromCache = false, cachedAt = null;

  CachedResult.cached(this.data, {required DateTime this.cachedAt})
    : fromCache = true;

  final T data;
  final bool fromCache;
  final DateTime? cachedAt;
}
