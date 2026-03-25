namespace DotnetApiSample.Models;

public sealed class CreateShareholderRequest
{
    public required string FirstName { get; init; }
    public required string LastName { get; init; }
    public required string Email { get; init; }
    public string? PhoneNumber { get; init; }
}

public sealed class PatchShareholderRequest
{
    public string? Email { get; init; }
    public string? PhoneNumber { get; init; }
}
