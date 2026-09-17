namespace AmuraWebsite.Services;

/// <summary>
/// Holds the WEBSITE_GUEST channel bearer token in memory so every quote
/// submission doesn't have to log in again. Registered as a singleton —
/// separate from InsurancePlatformClient itself, which is transient (comes
/// from AddHttpClient), so the token actually survives between requests.
/// </summary>
public sealed class PlatformTokenCache
{
    private readonly SemaphoreSlim _lock = new(1, 1);

    public string? Token { get; private set; }
    private DateTimeOffset _expiresAt = DateTimeOffset.MinValue;

    public bool HasValidToken => Token is not null && DateTimeOffset.UtcNow < _expiresAt;

    public async Task<IDisposable> LockAsync(CancellationToken ct)
    {
        await _lock.WaitAsync(ct);
        return new Releaser(_lock);
    }

    public void SetToken(string token, TimeSpan validFor)
    {
        Token = token;
        _expiresAt = DateTimeOffset.UtcNow + validFor;
    }

    public void Clear()
    {
        Token = null;
        _expiresAt = DateTimeOffset.MinValue;
    }

    private sealed class Releaser : IDisposable
    {
        private readonly SemaphoreSlim _semaphore;
        public Releaser(SemaphoreSlim semaphore) => _semaphore = semaphore;
        public void Dispose() => _semaphore.Release();
    }
}
