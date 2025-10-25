using System.Net;
using System.Text.RegularExpressions;

namespace Shared.Common;

public class ResponseModel
{
    public required StatusResponseModel status { get; set; }
}

public class ResponseModel<T> : ResponseModel
{
    public required T data { get; set; }
}

public class StatusResponseModel
{
    public HttpStatusCode statusCode { get; set; }
    public string statusMessage
    {
        get
        {
            var name = this.statusCode.ToString();

            if (name.Length <= 2 || name.All(char.IsUpper))
                return name;

            return Regex.Replace(name, "(?<!^)([A-Z])", " Solution");
        }
    }
    public string? bizErrorCode { get; set; } = default!;
    public string? bizErrorMessage { get; set; } = default!;
    public DateTime timestamp { get; set; }
}
