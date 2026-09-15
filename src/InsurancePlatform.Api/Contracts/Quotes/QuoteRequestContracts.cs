namespace InsurancePlatform.Api.Contracts.Quotes;

// ClientId is optional on every request here - "may not exist yet at quote
// stage" per the schema design doc (e.g. a USSD/WhatsApp quote for someone
// who hasn't registered as a Client at all). When the caller IS a
// Client-role user, the controller verifies whatever ClientId they send
// actually belongs to them (same ownership check VehiclesController uses)
// rather than trusting it blindly.
//
// Channel isn't derived from the caller's JWT/X-Channel header - the
// QuoteRequests table's CHECK constraint only allows PORTAL/WEBSITE/USSD/
// WHATSAPP, which doesn't include MOBILE (unlike Clients.registration_channel,
// which does). A mobile-app caller should currently send "PORTAL" here;
// this mismatch is worth resolving with a schema change later.

public class CreateMedicalIndividualQuoteRequest
{
    public long? ClientId { get; set; }

    // Channel is no longer part of the payload - quote requests can only be
    // made from the website now, so the proc hardcodes 'WEBSITE'.

    /// <summary>1. Customer Information - all required except OtherNames ("Others").</summary>
    public string IdNo { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? OtherNames { get; set; }
    public string Email { get; set; } = string.Empty;
    public string MobileNumber { get; set; } = string.Empty;

    /// <summary>2. Coverage Details - required, must be greater than zero.</summary>
    public decimal InpatientLimit { get; set; }

    /// <summary>3. Optional Benefits - a limit is only accepted when its benefit is enabled; Maternity has no limit (yes/no).</summary>
    public OptionalBenefitsDto? OptionalBenefits { get; set; }

    /// <summary>Zero or more dependants to cover alongside the individual - any number of Child entries allowed, at most one Spouse (checked in the controller, not by a DB constraint). Serialized to the family_members_json JSON column as-is.</summary>
    public List<FamilyMemberDto>? FamilyMembers { get; set; }
}

/// <summary>Optional benefits block on a Medical Individual quote request.</summary>
public class OptionalBenefitsDto
{
    public OptionalBenefitLimitDto? Outpatient { get; set; }

    /// <summary>Omitted or Enabled=false means the benefit is not taken.</summary>
    public OptionalBenefitLimitDto? Dental { get; set; }

    /// <summary>Maternity cover yes/no - no limit.</summary>
    public bool Maternity { get; set; }
}

/// <summary>A yes/no optional benefit that carries a limit when enabled.</summary>
public class OptionalBenefitLimitDto
{
    public bool Enabled { get; set; }
    public decimal? Limit { get; set; }
}

/// <summary>One dependant on a Medical Individual/Family quote request.</summary>
public class FamilyMemberDto
{
    /// <summary>"Spouse" or "Child" - case-insensitive, validated in the controller. At most one Spouse per request; any number of Child entries.</summary>
    public string Relationship { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public DateTime DateOfBirth { get; set; }
}

public class CreateMedicalCorporateQuoteRequest
{
    public long? ClientId { get; set; }
    public string Channel { get; set; } = string.Empty;

    /// <summary>The ID number of the person requesting on the company's behalf - not a company registration number.</summary>
    public string IdNo { get; set; } = string.Empty;
    public string CompanyName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
}

public class CreateProfessionalIndemnityQuoteRequest
{
    public long? ClientId { get; set; }
    public string Channel { get; set; } = string.Empty;

    /// <summary>Same "requester's own id_no" convention as CreateMedicalCorporateQuoteRequest.</summary>
    public string IdNo { get; set; } = string.Empty;
    public string ClientOrCompanyName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Profession { get; set; } = string.Empty;
}

public class CreateTravelQuoteRequest
{
    public long? ClientId { get; set; }
    public string Channel { get; set; } = string.Empty;

    /// <summary>Both new - Travel previously had neither (only the optional KraPin).</summary>
    public string IdNo { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string ClientName { get; set; } = string.Empty;
    public DateTime Dob { get; set; }
    public string? KraPin { get; set; }
    public string Destination { get; set; } = string.Empty;
    public DateTime TravelDateFrom { get; set; }
    public DateTime TravelDateTo { get; set; }
    public bool? TravellingWithFamily { get; set; }

    /// <summary>VACATION, BUSINESS or SPORTS.</summary>
    public string TripType { get; set; } = string.Empty;
}

/// <summary>TEMPORARY - mirrors QuoteRequestDomestic's placeholder details_json column until real fields are confirmed.</summary>
public class CreateDomesticQuoteRequest
{
    public long? ClientId { get; set; }
    public string Channel { get; set; } = string.Empty;

    /// <summary>Both new, pulled out ahead of the rest of Domestic's still-unconfirmed field list (DetailsJson stays as a placeholder for everything else).</summary>
    public string IdNo { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? DetailsJson { get; set; }
}

public class AssignQuoteRequestBackofficeRequest
{
    public long AssignedBackofficeUserId { get; set; }
}
