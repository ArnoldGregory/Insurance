using System.ComponentModel.DataAnnotations;

namespace InsurancePlatform.AdminPortal.Models;

/// <summary>Mirrors InsurancePlatform.Domain.Entities.ClientSummary - usp_Client_GetList's row shape (no Dob/Address/KraPin, see that class's own doc comment for why).</summary>
public class ClientSummary
{
    public long ClientId { get; set; }
    public string IdNo { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? Email { get; set; }
    public long? UserId { get; set; }
    public long? RegisteredByUserId { get; set; }
    public string RegistrationChannel { get; set; } = string.Empty;
    public DateTime CreatedOn { get; set; }
}

/// <summary>Mirrors ClientListPage - GET /api/clients's response shape (total count + one page of ClientSummary).</summary>
public class ClientListPage
{
    public long TotalCount { get; set; }
    public List<ClientSummary> Items { get; set; } = new();
}

/// <summary>Mirrors InsurancePlatform.Domain.Entities.Client - GET /api/clients/{id}'s full row.</summary>
public class ClientDetail
{
    public long ClientId { get; set; }
    public string IdNo { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public DateTime? Dob { get; set; }
    public string? Email { get; set; }
    public string Phone { get; set; } = string.Empty;
    public string? Address { get; set; }
    public string? KraPin { get; set; }
    public long? UserId { get; set; }
    public long? RegisteredByUserId { get; set; }
    public string RegistrationChannel { get; set; } = string.Empty;
    public DateTime CreatedOn { get; set; }
}

/// <summary>
/// Mirrors ClientLookupResult - GET /api/clients/resolve/{idNo}'s response.
/// MatchStatus is HAS_LOGIN / NO_LOGIN (a client record already exists,
/// ClientId/FullName/Phone/Email populated from it) or NOT_FOUND (nobody on
/// file - FullName/KraPin populated from GovConnect only if
/// EnrichedFromGovConnect is true).
/// </summary>
public class ClientLookupResult
{
    public string MatchStatus { get; set; } = string.Empty;
    public long? ClientId { get; set; }
    public string? FullName { get; set; }
    public string? Phone { get; set; }
    public string? Email { get; set; }
    public string? KraPin { get; set; }
    public bool EnrichedFromGovConnect { get; set; }
}

public class ClientIndexViewModel
{
    public List<ClientSummary> Items { get; set; } = new();
    public long TotalCount { get; set; }
    public string? Search { get; set; }
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;

    /// <summary>CREATE_CLIENT is held by AA/AG/SP, not SA - see RolePermissions in Insurance_API_Schema.sql.</summary>
    public bool CanCreate { get; set; }

    /// <summary>EDIT_CLIENT is held by AA/SP only - not AG, not SA.</summary>
    public bool CanEdit { get; set; }

    public string? StatusMessage { get; set; }
    public bool StatusIsError { get; set; }

    public int TotalPages => PageSize <= 0 ? 1 : (int)Math.Ceiling(TotalCount / (double)PageSize);
}

/// <summary>Step 1 of Create: just the ID number, looked up via GET /api/clients/resolve/{idNo} before showing any other field.</summary>
public class ClientLookupViewModel
{
    [Required(ErrorMessage = "Enter an ID number to look up.")]
    [Display(Name = "ID Number")]
    public string IdNo { get; set; } = string.Empty;

    public string? ErrorMessage { get; set; }
}

/// <summary>Step 2 of Create - shown once Resolve comes back NOT_FOUND, prefilled from GovConnect where available.</summary>
public class ClientCreateViewModel
{
    [Required]
    public string IdNo { get; set; } = string.Empty;

    [Required(ErrorMessage = "Full name is required.")]
    [Display(Name = "Full name")]
    public string FullName { get; set; } = string.Empty;

    [Display(Name = "Date of birth")]
    [DataType(DataType.Date)]
    public DateTime? Dob { get; set; }

    [EmailAddress(ErrorMessage = "Enter a valid email address.")]
    public string? Email { get; set; }

    [Required(ErrorMessage = "Phone number is required.")]
    public string Phone { get; set; } = string.Empty;

    public string? Address { get; set; }

    [Display(Name = "KRA PIN")]
    public string? KraPin { get; set; }

    /// <summary>Fixed at PORTAL - a client created here was registered by staff through the Admin Portal, never USSD/WHATSAPP/WEBSITE.</summary>
    public string RegistrationChannel { get; set; } = "PORTAL";

    public bool WasEnrichedFromGovConnect { get; set; }
    public string? ErrorMessage { get; set; }
}

public class ClientEditViewModel
{
    public long ClientId { get; set; }

    /// <summary>Display-only - ID numbers aren't editable once a client is created.</summary>
    public string IdNo { get; set; } = string.Empty;

    [Required(ErrorMessage = "Full name is required.")]
    [Display(Name = "Full name")]
    public string FullName { get; set; } = string.Empty;

    [Display(Name = "Date of birth")]
    [DataType(DataType.Date)]
    public DateTime? Dob { get; set; }

    [EmailAddress(ErrorMessage = "Enter a valid email address.")]
    public string? Email { get; set; }

    [Required(ErrorMessage = "Phone number is required.")]
    public string Phone { get; set; } = string.Empty;

    public string? Address { get; set; }

    [Display(Name = "KRA PIN")]
    public string? KraPin { get; set; }

    public string? ErrorMessage { get; set; }
}
