namespace DotnetApiSample.Models;

public sealed class SearchEventSessionsRequest
{
    public List<string>? Tags { get; init; }
    public List<string>? Languages { get; init; }
    public List<DeliveryMode>? DeliveryModes { get; init; }
    public decimal? MinimumRating { get; init; }
    public string? SpeakerQuery { get; init; }
}

public sealed class SearchEventSessionsResponse
{
    public required Guid EventId { get; init; }
    public required SessionSearchFilters AppliedFilters { get; init; }
    public required PagingInfo Paging { get; init; }
    public required List<EventSessionSummary> Sessions { get; init; }
    public string? CorrelationId { get; init; }
    public string? TenantId { get; init; }
}

public sealed class SessionSearchFilters
{
    public required DateTimeOffset From { get; init; }
    public required DateTimeOffset To { get; init; }
    public bool IncludeSoldOut { get; init; }
    public required SessionSortBy SortBy { get; init; }
    public required SortDirection SortDirection { get; init; }
    public List<string>? Languages { get; init; }
    public List<string>? Tags { get; init; }
    public decimal? MinimumRating { get; init; }
    public List<DeliveryMode>? DeliveryModes { get; init; }
    public string? SpeakerQuery { get; init; }
}

public sealed class PagingInfo
{
    public int Page { get; init; }
    public int PageSize { get; init; }
    public int Total { get; init; }
}

public sealed class EventSessionSummary
{
    public required Guid SessionId { get; init; }
    public required string Title { get; init; }
    public required string Room { get; init; }
    public required DateTimeOffset StartTime { get; init; }
    public required DateTimeOffset EndTime { get; init; }
    public required DeliveryMode DeliveryMode { get; init; }
    public required SessionStatus Status { get; init; }
    public int AvailableSeats { get; init; }
    public required List<string> SpeakerNames { get; init; }
}

public enum DeliveryMode
{
    InPerson,
    Virtual,
    Hybrid
}

public enum SessionStatus
{
    Open,
    Waitlist,
    SoldOut,
    Cancelled
}

public enum SessionSortBy
{
    StartTime,
    Title,
    AvailableSeats,
    Rating
}

public enum SortDirection
{
    Asc,
    Desc
}
