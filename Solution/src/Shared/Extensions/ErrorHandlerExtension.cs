using System;
using System.Globalization;
using System.Text.Json;

namespace Shared.Extensions;

public class ErrorHandlerExtension
{
    private static readonly Dictionary<string, string> ErrorMessages = new();
    private static readonly Dictionary<string, string> LocalizedErrorMessages = new();

    internal class ErrorItem
    {
        public required string code { get; set; }
        public required string message { get; set; }
    }

    static ErrorHandlerExtension()
    {
        LoadErrorMessages("resources/error.json", ErrorMessages);

        var language = CultureInfo.CurrentCulture.TwoLetterISOLanguageName;
        var localizedFile = $"resources/error.{language}.json";
        if (File.Exists(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, localizedFile)))
        {
            LoadErrorMessages(localizedFile, LocalizedErrorMessages);
        }
    }

    private static void LoadErrorMessages(string filePath, Dictionary<string, string> target)
    {
        var fullPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, filePath);
        if (!File.Exists(fullPath)) return;

        var json = File.ReadAllText(fullPath);
        var items = JsonSerializer.Deserialize<List<ErrorItem>>(json);
        if (items != null)
        {
            foreach (var item in items)
            {
                if (!string.IsNullOrWhiteSpace(item.code))
                    target[item.code] = item.message;
            }
        }
    }

    public static string GetErrorMessage(string code, string? language = null)
    {
        if (string.IsNullOrWhiteSpace(code))
        {
            return default!;
        }

        Dictionary<string, string>? tempMessages = null;

        if (!string.IsNullOrEmpty(language))
        {
            var localizedFilePath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, $"resources/error.{language}.json");
            if (File.Exists(localizedFilePath))
            {
                var json = File.ReadAllText(localizedFilePath);
                var items = JsonSerializer.Deserialize<List<ErrorItem>>(json);
                tempMessages = new Dictionary<string, string>();
                if (items != null)
                {
                    var item = items.FirstOrDefault(x => x.code == code);
                    if (item == null) return default!;

                    tempMessages[item.code] = item.message;
                }
            }
        }
        else
        {
            var defaultFilePath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "resources/error.json");
            if (File.Exists(defaultFilePath))
            {
                var json = File.ReadAllText(defaultFilePath);
                var items = JsonSerializer.Deserialize<List<ErrorItem>>(json);
                tempMessages = new Dictionary<string, string>();
                if (items != null)
                {
                    var item = items.FirstOrDefault(x => x.code == code);
                    if (item == null) return default!;

                    tempMessages[item.code] = item.message;
                }
            }
        }

        if (tempMessages != null && tempMessages.TryGetValue(code, out var message))
        {
            return message;
        }

        if (LocalizedErrorMessages.TryGetValue(code, out var fallbackLocalized))
        {
            return fallbackLocalized;
        }

        if (ErrorMessages.TryGetValue(code, out var defaultMessage))
        {
            return defaultMessage;
        }

        return default!;
    }
}
