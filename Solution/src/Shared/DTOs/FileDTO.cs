using System;

namespace Shared.DTOs;

public class FileDTO
{
    public required string fileName { get; set; }
    public required byte[] file { get; set; }
    public required string mimeType { get; set; }
    public required long size { get; set; }
    public string description { get; set; } = default!;
}

