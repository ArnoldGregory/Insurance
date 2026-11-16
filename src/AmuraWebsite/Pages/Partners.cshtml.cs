using Microsoft.AspNetCore.Mvc.RazorPages;

namespace AmuraWebsite.Pages;

public class PartnersModel : PageModel
{
    /// <summary>
    /// Licensed insurers Amura arranges cover with. Names only for now - the
    /// client will supply official logo artwork, which replaces the name
    /// placeholder on each card without any markup change.
    /// </summary>
    public IReadOnlyList<string> Partners { get; } = new[]
    {
        "APA Insurance",
        "Definite Assurance",
        "Fidelity Shield",
        "Heritage Insurance",
        "Kenindia Assurance",
        "Kenya Orient Insurance",
        "Monarch Insurance",
        "MUA Insurance",
        "Old Mutual",
        "Pacis Insurance",
        "Pioneer Insurance"
    };

    public void OnGet()
    {
    }
}
