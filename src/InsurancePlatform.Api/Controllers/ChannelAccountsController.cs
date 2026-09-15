using System.Text.RegularExpressions;
using InsurancePlatform.Api.Contracts.ChannelAccounts;
using InsurancePlatform.Api.Contracts.Common;
using InsurancePlatform.Api.Logging;
using InsurancePlatform.Application.Auth;
using InsurancePlatform.Application.Repositories;
using InsurancePlatform.Domain.Common;
using InsurancePlatform.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace InsurancePlatform.Api.Controllers;

/// <summary>SuperAdmin-only administration of ChannelServiceAccounts (USSD/WhatsApp/website-guest/future integrations) - the machine credentials POST /api/auth/channel-login authenticates against.</summary>
// Every action here requires MANAGE_CHANNELS, seeded to SuperAdmin only
// (Insurance_API_Schema.sql's RolePermissions block) - these are
// system-level credentials, not something AgentAdmin's
// client/agent/pricing-management scope covers. Create/RegenerateKey are
// the only two places a plaintext API key ever exists outside a channel
// integration's own config - it's generated here, hashed immediately, and
// returned to the caller exactly once. There is no GET-the-key-back
// endpoint anywhere, by design, same as a password can't be read back.
[ApiController]
[Route("api/channel-accounts")]
[Authorize(Policy = PermissionCodes.ManageChannels)]
public class ChannelAccountsController : BaseApiController
{
    // Uppercase letters/digits/underscore only, 2-20 chars - matches the
    // VARCHAR(20) column width and keeps channel names readable/
    // predictable (USSD, WHATSAPP, WEBSITE_GUEST, TELEGRAM_BOT, ...)
    // without the DB-level CHECK constraint that used to hard-code the
    // exact 3 allowed values.
    private static readonly Regex ChannelPattern = new("^[A-Z0-9_]{2,20}$", RegexOptions.Compiled);

    private readonly IChannelServiceRepository _channelServiceRepository;
    private readonly ILoggerManager _logger;

    public ChannelAccountsController(IChannelServiceRepository channelServiceRepository, ILoggerManager logger, CorrelationContext correlationContext)
        : base(correlationContext)
    {
        _channelServiceRepository = channelServiceRepository;
        _logger = logger;
    }

    /// <summary>Registers a brand-new channel integration. Returns the plaintext API key ONCE - copy it now, it cannot be retrieved again.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<ChannelAccountCreateResult>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Create([FromBody] CreateChannelAccountRequest request)
    {
        var channel = request.Channel?.Trim().ToUpperInvariant() ?? string.Empty;

        if (!ChannelPattern.IsMatch(channel))
        {
            return BusinessFailure("channel must be 2-20 characters: uppercase letters, digits, or underscore only.");
        }

        var plaintextKey = ApiKeyHasher.GenerateKey();
        var keyHash = ApiKeyHasher.Hash(plaintextKey);

        var result = await _channelServiceRepository.CreateAsync(channel, keyHash, request.AllowedIpRange, CurrentUserId);

        if (!result.IsSuccess || result.Data is null)
        {
            _logger.LogWarn($"Channel account create failed for channel={channel}: {result.ResultMessage}");
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Channel account created: service_account_id={result.Data}, channel={channel}, by user_id={CurrentUserId}.");

        var data = new ChannelAccountCreateResult
        {
            ServiceAccountId = result.Data.Value,
            Channel = channel,
            ApiKey = plaintextKey
        };

        return Success(data, "Channel account created. Copy the ApiKey now - it will not be shown again.");
    }

    /// <summary>Lists every registered channel account - never includes the key hash.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<ChannelServiceAccountSummary>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList()
    {
        var result = await _channelServiceRepository.GetListAsync();

        if (!result.IsSuccess)
        {
            _logger.LogError($"usp_ChannelServiceAccount_GetList returned ResultCode={result.ResultCode}: {result.ResultMessage}");
            return ServerError(result.ResultMessage);
        }

        return Success(result.Data, result.ResultMessage);
    }

    /// <summary>Activates or deactivates a channel account - soft toggle, same shape as everywhere else's soft delete/status flip.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpPut("{id}/status")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SetStatus(long id, [FromBody] SetChannelAccountStatusRequest request)
    {
        var result = await _channelServiceRepository.SetStatusAsync(id, request.IsActive, CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Channel account status changed: service_account_id={id}, is_active={request.IsActive}, by user_id={CurrentUserId}.");
        return Success(result.ResultMessage);
    }

    /// <summary>Issues a brand-new key for an existing channel (e.g. rotating a compromised key) without touching the channel name. Returns the plaintext key ONCE - same rule as Create.</summary>
    /// <response code="200">Always 200 - check Success in the body.</response>
    [HttpPost("{id}/regenerate-key")]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    public async Task<IActionResult> RegenerateKey(long id)
    {
        var plaintextKey = ApiKeyHasher.GenerateKey();
        var keyHash = ApiKeyHasher.Hash(plaintextKey);

        var result = await _channelServiceRepository.RegenerateKeyAsync(id, keyHash, CurrentUserId);

        if (!result.IsSuccess)
        {
            return BusinessFailure(result.ResultMessage);
        }

        _logger.LogInfo($"Channel account key regenerated: service_account_id={id}, by user_id={CurrentUserId}.");
        return Success(new { ApiKey = plaintextKey }, "Key regenerated. Copy it now - it will not be shown again.");
    }
}
