using System;

namespace Shared.Configurations;


public class AppSettings
{
    public ConnectionStrings ConnectionStrings { get; set; } = new();
    public RedisOptions Redis { get; set; } = new();
    public EncryptionOptions Encryption { get; set; } = new();
    public EncryptionOptions DbEncryption { get; set; } = new();
    public TokenOptions Token { get; set; } = new();
    public PaginationOptions Pagination { get; set; } = new();
}

public class ConnectionStrings
{
    public string DefaultConnection { get; set; } = string.Empty;
}

public class RedisOptions
{
    public string Host { get; set; } = string.Empty;
    public int Port { get; set; }
    public string Password { get; set; } = string.Empty;
}

public class EncryptionOptions
{
    public string Key { get; set; } = string.Empty;
    public string IV { get; set; } = string.Empty;
}

public class TokenOptions
{
    public int ExpireBufferMinutes { get; set; } = 15;
    public int AccessTokenExpirationMinutes { get; set; } = 60;
    public int RefreshTokenExpirationDays { get; set; } = 30;
}

public class PaginationOptions
{
    public int DefaultPageSize { get; set; } = 20;
}
