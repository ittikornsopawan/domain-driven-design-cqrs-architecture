using System.Net;
using Shared.Common;
using Shared.Configurations;
using Shared.Extensions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Options;

namespace Presentation.Controllers;

public class BaseController : ControllerBase, IActionFilter
{
    public readonly AppSettings _appSettings;
    public HeaderModel? _header;

    public BaseController(IOptions<AppSettings> appSettings)
    {
        _appSettings = appSettings.Value;
    }

    [NonAction]
    public void OnActionExecuting(ActionExecutingContext context)
    {
        var accessToken = Request.Headers["Authorization"].FirstOrDefault();
        if (!string.IsNullOrEmpty(accessToken)) accessToken = accessToken.Substring("Bearer ".Length);

        _header = new HeaderModel
        {
            accessToken = accessToken ?? string.Empty,
            refreshAccessToken = Request.Headers["refresh-access-token"].FirstOrDefault() ?? string.Empty,
            clientId = Request.Headers["client-id"].FirstOrDefault() ?? string.Empty,
            clientSecret = Request.Headers["client-secret"].FirstOrDefault() ?? string.Empty,
            deviceId = Request.Headers["device-id"].FirstOrDefault() ?? string.Empty,
            userAgent = Request.Headers.UserAgent.ToString() ?? string.Empty,
            ipAddress = Request.HttpContext.Connection.RemoteIpAddress?.ToString() ?? string.Empty
        };
    }

    [NonAction]
    public void OnActionExecuted(ActionExecutedContext context)
    {
    }

    protected IActionResult ResponseHandler(HttpStatusCode statusCode = HttpStatusCode.OK)
    {
        return StatusCode((int)statusCode, new ResponseModel
        {
            status = new StatusResponseModel
            {
                statusCode = statusCode,
                timestamp = DateTime.UtcNow
            }
        });
    }

    protected IActionResult ResponseHandler(HttpStatusCode statusCode = HttpStatusCode.OK, string? bizErrorCode = null)
    {
        return StatusCode((int)statusCode, new ResponseModel
        {
            status = new StatusResponseModel
            {
                statusCode = statusCode,
                bizErrorCode = bizErrorCode,
                bizErrorMessage = ErrorHandlerExtension.GetErrorMessage(bizErrorCode ?? string.Empty),
                timestamp = DateTime.UtcNow
            }
        });
    }

    protected IActionResult ResponseHandler<T>(T result, HttpStatusCode statusCode = HttpStatusCode.OK, string? bizErrorCode = null)
    {
        return StatusCode((int)statusCode, new ResponseModel<T>
        {
            status = new StatusResponseModel
            {
                statusCode = statusCode,
                bizErrorCode = bizErrorCode,
                bizErrorMessage = ErrorHandlerExtension.GetErrorMessage(bizErrorCode ?? string.Empty),
                timestamp = DateTime.UtcNow
            },
            data = result
        });
    }
}
