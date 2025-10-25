using System;

namespace Shared.Common;

public class HeaderModel
{
    public string accessToken { get; set; } = string.Empty;
    public string refreshAccessToken { get; set; } = string.Empty;
    public string clientId { get; set; } = string.Empty;
    public string clientSecret { get; set; } = string.Empty;
    public string deviceId { get; set; } = string.Empty;
    public string userAgent { get; set; } = string.Empty;
    public string ipAddress { get; set; } = string.Empty;
    public DateTime timestamp { get; set; } = DateTime.UtcNow;
}
