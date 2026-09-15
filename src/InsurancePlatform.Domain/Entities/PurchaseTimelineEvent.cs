namespace InsurancePlatform.Domain.Entities;

public class PurchaseTimelineEvent
{
    public string EventType { get; set; } = string.Empty;
    public int StepOrder { get; set; }
    public long RefId { get; set; }
    public DateTime EventTime { get; set; }
    public string EventDataJson { get; set; } = "{}";
}
