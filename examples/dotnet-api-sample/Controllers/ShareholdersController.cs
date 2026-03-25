using DotnetApiSample.Models;
using Microsoft.AspNetCore.Mvc;

namespace DotnetApiSample.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ShareholdersController : ControllerBase
{
    [HttpGet("lite")]
    public IActionResult GetShareholdersLite(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 25,
        [FromHeader(Name = "x-correlation-id")] string? correlationId = null)
    {
        var result = new[]
        {
            new { id = Guid.NewGuid(), name = "Alex Doe", page, pageSize, correlationId }
        };

        return Ok(result);
    }

    [HttpGet("{shareholderId:guid}")]
    public IActionResult GetShareholder(
        [FromRoute] Guid shareholderId,
        [FromHeader(Name = "x-correlation-id")] string? correlationId = null)
    {
        return Ok(new { shareholderId, name = "Alex Doe", correlationId });
    }

    [HttpPost]
    public IActionResult CreateShareholder([FromBody] CreateShareholderRequest request)
    {
        var createdId = Guid.NewGuid();

        return CreatedAtAction(
            nameof(GetShareholder),
            new { shareholderId = createdId },
            new { shareholderId = createdId, request.FirstName, request.LastName, request.Email });
    }

    [HttpPatch("{shareholderId:guid}")]
    public IActionResult PatchShareholder(
        [FromRoute] Guid shareholderId,
        [FromBody] PatchShareholderRequest request)
    {
        return Ok(new { shareholderId, request.Email, request.PhoneNumber });
    }
}
