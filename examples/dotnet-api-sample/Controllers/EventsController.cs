using DotnetApiSample.Models;
using Microsoft.AspNetCore.Mvc;

namespace DotnetApiSample.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EventsController : ControllerBase
{
    [HttpPost("{eventId:guid}/registrations")]
    public IActionResult CreateRegistration(
        [FromRoute] Guid eventId,
        [FromBody] CreateRegistrationRequest request,
        [FromHeader(Name = "x-correlation-id")] string? correlationId = null)
    {
        return Ok(new
        {
            eventId,
            request.AttendeeEmail,
            request.AttendeeName,
            request.TicketType,
            correlationId
        });
    }

    [HttpPost("{eventId:guid}/sessions/search")]
    public ActionResult<SearchEventSessionsResponse> SearchSessions(
        [FromRoute] Guid eventId,
        [FromBody] SearchEventSessionsRequest request,
        [FromQuery] DateTimeOffset? from = null,
        [FromQuery] DateTimeOffset? to = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        [FromQuery] bool includeSoldOut = false,
        [FromQuery] SessionSortBy sortBy = SessionSortBy.StartTime,
        [FromQuery] SortDirection sortDirection = SortDirection.Asc,
        [FromHeader(Name = "x-correlation-id")] string? correlationId = null,
        [FromHeader(Name = "x-tenant-id")] string? tenantId = null)
    {
        if (request.Tags is { Count: > 10 })
        {
            return BadRequest("At most 10 tags are allowed.");
        }

        var effectiveFrom = from ?? DateTimeOffset.UtcNow;
        var effectiveTo = to ?? effectiveFrom.AddDays(30);

        if (effectiveTo < effectiveFrom)
        {
            return BadRequest("'to' must be greater than or equal to 'from'.");
        }

        var sessions = new List<EventSessionSummary>
        {
            new()
            {
                SessionId = Guid.NewGuid(),
                Title = "Opening Keynote",
                Room = "Main Hall",
                StartTime = effectiveFrom.AddHours(2),
                EndTime = effectiveFrom.AddHours(3),
                DeliveryMode = DeliveryMode.InPerson,
                Status = includeSoldOut ? SessionStatus.SoldOut : SessionStatus.Open,
                AvailableSeats = includeSoldOut ? 0 : 24,
                SpeakerNames = new List<string> { "Dana River", "Avery Stone" }
            },
            new()
            {
                SessionId = Guid.NewGuid(),
                Title = "API Design Workshop",
                Room = "Studio 2",
                StartTime = effectiveFrom.AddHours(5),
                EndTime = effectiveFrom.AddHours(7),
                DeliveryMode = DeliveryMode.Hybrid,
                Status = SessionStatus.Open,
                AvailableSeats = 12,
                SpeakerNames = new List<string> { "Jordan Lee" }
            }
        };

        var response = new SearchEventSessionsResponse
        {
            EventId = eventId,
            AppliedFilters = new SessionSearchFilters
            {
                From = effectiveFrom,
                To = effectiveTo,
                IncludeSoldOut = includeSoldOut,
                SortBy = sortBy,
                SortDirection = sortDirection,
                Languages = request.Languages,
                Tags = request.Tags,
                MinimumRating = request.MinimumRating,
                DeliveryModes = request.DeliveryModes,
                SpeakerQuery = request.SpeakerQuery
            },
            Paging = new PagingInfo
            {
                Page = page,
                PageSize = pageSize,
                Total = 2
            },
            Sessions = sessions,
            CorrelationId = correlationId,
            TenantId = tenantId
        };

        return Ok(response);
    }
}
