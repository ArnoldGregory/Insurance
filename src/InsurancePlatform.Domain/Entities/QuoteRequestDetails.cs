namespace InsurancePlatform.Domain.Entities;

// One class per QuoteRequest<Type> detail table - each usp_QuoteRequest<Type>_GetDetail
// proc is a plain SELECT * with no existence check of its own (no
// proc_label, no NOT_FOUND result code), so a caller passing a
// quote_request_id that exists but is the wrong type (or doesn't exist at
// all) just gets zero rows back - the repository/controller layer treats a
// null Data the same way ClientRepository.GetByIdAsync does.

public class QuoteRequestMedicalIndividualDetail
{
    public long QuoteRequestId { get; set; }

    /// <summary>1. Customer Information - id_no, first_name, last_name, other_names, email, mobile_number (see medical_individual_fields_migration.sql).</summary>
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;

    /// <summary>"Others" - optional middle/other names.</summary>
    public string? OtherNames { get; set; }

    /// <summary>Parsed from the family_members_json column - null if there were none, or if a legacy row's JSON doesn't match this shape.</summary>
    public List<FamilyMember>? FamilyMembers { get; set; }
    public string IdNo { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string MobileNumber { get; set; } = string.Empty;

    /// <summary>2. Coverage Details - inpatient limit.</summary>
    public decimal InpatientLimit { get; set; }

    /// <summary>3. Optional Benefits - limits only populated when the matching flag is on; Maternity is yes/no with no limit.</summary>
    public bool HasOutpatient { get; set; }
    public decimal? OutpatientLimit { get; set; }
    public bool HasDental { get; set; }
    public decimal? DentalLimit { get; set; }
    public bool HasMaternity { get; set; }

    /// <summary>Display name composed from the name parts - used for notification emails.</summary>
    public string FullName
    {
        get
        {
            var parts = new[] { FirstName, LastName, OtherNames }.Where(p => !string.IsNullOrWhiteSpace(p));
            return string.Join(" ", parts);
        }
    }
}

/// <summary>One dependant on a Medical Individual/Family quote request - read-side shape (see Api.Contracts.Quotes.FamilyMemberDto for the write-side equivalent; kept separate so Domain doesn't depend on the Api project).</summary>
public class FamilyMember
{
    /// <summary>"Spouse" or "Child".</summary>
    public string Relationship { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public DateTime DateOfBirth { get; set; }
}

public class QuoteRequestMedicalCorporateDetail
{
    public long QuoteRequestId { get; set; }

    /// <summary>The ID number of the person requesting on the company's behalf - not a company registration number.</summary>
    public string IdNo { get; set; } = string.Empty;
    public string CompanyName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
}

public class QuoteRequestProfessionalIndemnityDetail
{
    public long QuoteRequestId { get; set; }

    /// <summary>Same "requester's own id_no" convention as QuoteRequestMedicalCorporateDetail.</summary>
    public string IdNo { get; set; } = string.Empty;
    public string ClientOrCompanyName { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Profession { get; set; } = string.Empty;
    public string? ProposalFormStatus { get; set; }
}

public class QuoteRequestTravelDetail
{
    public long QuoteRequestId { get; set; }

    /// <summary>Added alongside Email - Travel previously had neither (only the optional KraPin).</summary>
    public string IdNo { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string ClientName { get; set; } = string.Empty;
    public DateTime Dob { get; set; }
    public string? KraPin { get; set; }
    public string Destination { get; set; } = string.Empty;
    public DateTime TravelDateFrom { get; set; }
    public DateTime TravelDateTo { get; set; }
    public bool TravellingWithFamily { get; set; }
    public string TripType { get; set; } = string.Empty;
}

/// <summary>TEMPORARY - details_json mirrors QuoteRequestDomestic's placeholder column until the rest of Domestic's real fields are confirmed; IdNo/Email are real required columns already (see the migration).</summary>
public class QuoteRequestDomesticDetail
{
    public long QuoteRequestId { get; set; }
    public string IdNo { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? DetailsJson { get; set; }
}
