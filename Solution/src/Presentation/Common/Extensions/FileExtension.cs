using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Shared.DTOs;

namespace Presentation.Common.Extensions;

public static class FileExtension
{
    public static async Task<FileDTO> ToFileAsync(this IFormFile formFile, string? description = null)
    {
        using var memoryStream = new MemoryStream();
        await formFile.CopyToAsync(memoryStream);

        return new FileDTO
        {
            fileName = formFile.FileName,
            file = memoryStream.ToArray(),
            mimeType = formFile.ContentType,
            size = formFile.Length,
            description = description ?? string.Empty
        };
    }
}
