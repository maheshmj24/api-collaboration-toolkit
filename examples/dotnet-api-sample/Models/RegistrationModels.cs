namespace DotnetApiSample.Models;

public sealed class CreateRegistrationRequest
{
    public required string AttendeeName { get; init; }
    public required string AttendeeEmail { get; init; }
    public required string TicketType { get; init; }
}
