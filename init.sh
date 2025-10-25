#!/usr/bin/env bash
# --------------------------------------------
# Clean Architecture Shell Generator (.NET 9)
# Usage: ./init.sh <SolutionName>
# --------------------------------------------

if [ -z "$1" ]; then
  echo "❌ Please provide a solution name: ./init.sh Products"
  exit 1
fi

SOLUTION_NAME=$1

# Create folders
mkdir -p $SOLUTION_NAME/src
mkdir -p $SOLUTION_NAME/test
cd $SOLUTION_NAME

# Create solution
dotnet new sln -n $SOLUTION_NAME

# Create projects
dotnet new webapi -n "Presentation" -o "src/Presentation"
dotnet new classlib -n "Application" -o "src/Application"
dotnet new classlib -n "Domain" -o "src/Domain"
dotnet new classlib -n "Infrastructure" -o "src/Infrastructure"
dotnet new classlib -n "Shared" -o "src/Shared"
dotnet new console -n Migrator -o src/Migrator

dotnet new xunit -n "Application.Test" -o "test/Application.Test"
dotnet new xunit -n "Domain.Test" -o "test/Domain.Test"

# Add projects to solution
dotnet sln add src/Presentation/Presentation.csproj
dotnet sln add src/Application/Application.csproj
dotnet sln add src/Domain/Domain.csproj
dotnet sln add src/Infrastructure/Infrastructure.csproj
dotnet sln add src/Shared/Shared.csproj
dotnet sln add src/Migrator/Migrator.csproj
dotnet sln add test/Application.Test/Application.Test.csproj
dotnet sln add test/Domain.Test/Domain.Test.csproj

# Add project references
dotnet add src/Presentation/Presentation.csproj reference \
    src/Application/Application.csproj \
    src/Shared/Shared.csproj

dotnet add src/Application/Application.csproj reference \
    src/Domain/Domain.csproj \
    src/Shared/Shared.csproj

dotnet add src/Infrastructure/Infrastructure.csproj reference \
    src/Shared/Shared.csproj

dotnet add test/Application.Test/Application.Test.csproj reference \
    src/Application/Application.csproj

dotnet add test/Domain.Test/Domain.Test.csproj reference \
    src/Domain/Domain.csproj



# NuGet packages per project
PACKAGES=(
  "src/Presentation:AutoMapper:15.0.1"
  "src/Presentation:AutoMapper.Extensions.Microsoft.DependencyInjection:12.0.1"
  "src/Presentation:FluentValidation:12.0.0"
  "src/Presentation:FluentValidation.DependencyInjectionExtensions:12.0.0"
  "src/Presentation:MediatR:13.0.0"
  "src/Presentation:Microsoft.AspNetCore.OpenApi:9.0.9"
  "src/Presentation:Microsoft.EntityFrameworkCore:9.0.9"
  "src/Presentation:Microsoft.EntityFrameworkCore.Design:9.0.9"
  "src/Presentation:Microsoft.EntityFrameworkCore.Relational:9.0.9"
  "src/Presentation:Npgsql.EntityFrameworkCore.PostgreSQL:9.0.4"
  "src/Presentation:Serilog.AspNetCore:9.0.0"
  "src/Presentation:Serilog.Settings.Configuration:9.0.0"
  "src/Presentation:Swashbuckle.AspNetCore:9.0.4"

  "src/Application:AutoMapper:15.0.1"
  "src/Application:AutoMapper.Extensions.Microsoft.DependencyInjection:12.0.1"
  "src/Application:FluentValidation:12.0.0"
  "src/Application:FluentValidation.DependencyInjectionExtensions:12.0.0"
  "src/Application:MediatR:13.0.0"

  "src/Domain:MediatR:13.0.0"
  "src/Domain:Microsoft.Extensions.DependencyInjection:9.0.9"

  "src/Infrastructure:AutoMapper:15.0.1"
  "src/Infrastructure:AutoMapper.Extensions.Microsoft.DependencyInjection:12.0.1"
  "src/Infrastructure:MediatR:13.0.0"
  "src/Infrastructure:Microsoft.EntityFrameworkCore:9.0.9"
  "src/Infrastructure:Microsoft.EntityFrameworkCore.Design:9.0.9"
  "src/Infrastructure:Microsoft.EntityFrameworkCore.Relational:9.0.9"
  "src/Infrastructure:Microsoft.Extensions.DependencyInjection:9.0.9"
  "src/Infrastructure:Npgsql.EntityFrameworkCore.PostgreSQL:9.0.4"

  "src/Migrator:Microsoft.Extensions.Configuration:9.0.9"
  "src/Migrator:Microsoft.Extensions.Configuration.Binder:9.0.9"
  "src/Migrator:Microsoft.Extensions.Configuration.Json:9.0.9"
  "src/Migrator:Microsoft.Extensions.DependencyInjection:9.0.9"
  "src/Migrator:Microsoft.Extensions.Logging:9.0.9"
  "src/Migrator:Npgsql:9.0.3"
)

echo "INSTALL PACKAGE"
for p in "${PACKAGES[@]}"; do
  proj="${p%%:*}"
  pkg="${p#*:}"
  name="${pkg%%:*}"
  version="${pkg##*:}"
  dotnet add "$proj/${proj##*/}.csproj" package "$name" --version "$version"
done

# Cleanup default files
find . -type f -name "Class1.cs" -delete
find . -type f -name "WeatherForecast.cs" -delete
find . -type f -name "WeatherForecastController.cs" -delete
find . -type f -name "UnitTest1.cs" -delete

# Create subfolders in Presentation and add .gitkeep
mkdir -p src/Presentation/Common
mkdir -p src/Presentation/Common/Attributes
mkdir -p src/Presentation/Common/Behaviors
mkdir -p src/Presentation/Common/Extensions

mkdir -p src/Presentation/Logs
mkdir -p src/Presentation/Models
mkdir -p src/Presentation/Requests
mkdir -p src/Presentation/Resources

PRES_SUBFOLDERS=(
  "Common"
  "Common/Attributes"
  "Common/Behaviors"
  "Common/Extensions"
  "Logs"
  "Models"
  "Requests"
  "Resources"
)

for sub in "${PRES_SUBFOLDERS[@]}"; do
  folder="src/Presentation/$sub"
  mkdir -p "$folder"
  touch "$folder/.gitkeep"
done

ENV_FILES=(
  "appsettings.Development.json"
  "appsettings.QA.json"
  "appsettings.UAT.json"
  "appsettings.SIT.json"
  "appsettings.Production.json"
)

for file in "${ENV_FILES[@]}"; do
  touch "src/Presentation/$file"
done

for file in "${ENV_FILES[@]}"; do
  cat > "src/Presentation/$file" <<EOL
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
EOL
done

# Create Behaviors folder and ValidationBehavior.cs
mkdir -p src/Presentation/Common/Behaviors

cat <<EOL > src/Presentation/Common/Behaviors/ValidationBehavior.cs
using FluentValidation;
using MediatR;

namespace Presentation.Common.Behaviors;

public class ValidationBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly IEnumerable<IValidator<TRequest>> _validators;

    public ValidationBehavior(IEnumerable<IValidator<TRequest>> validators)
    {
        _validators = validators;
    }

    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken cancellationToken)
    {
        if (_validators.Any())
        {
            var context = new ValidationContext<TRequest>(request);
            var validationResults = await Task.WhenAll(
                _validators.Select(v => v.ValidateAsync(context, cancellationToken)));

            var failures = validationResults
                .SelectMany(r => r.Errors)
                .Where(f => f != null)
                .ToList();

            if (failures.Count != 0)
                throw new ValidationException(failures);
        }

        return await next();
    }
}
EOL

# Create subfolders in Application and add .gitkeep

# Create Extensions folder and FileExtension.cs
mkdir -p src/Presentation/Common/Extensions

cat <<EOL > src/Presentation/Common/Extensions/FileExtension.cs
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
EOL

mkdir -p src/Application/Common

PRES_SUBFOLDERS=(
  "Common"
)

for sub in "${PRES_SUBFOLDERS[@]}"; do
  folder="src/Application/$sub"
  mkdir -p "$folder"
  touch "$folder/.gitkeep"
done

# Create DependencyInjection.cs in Application
cat <<EOL > src/Application/DependencyInjection.cs
using FluentValidation;
using Microsoft.Extensions.DependencyInjection;
using System.Reflection;

namespace Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        var assembly = Assembly.GetExecutingAssembly();

        services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(assembly));

        services.AddAutoMapper(assembly);
        services.AddValidatorsFromAssembly(assembly);

        RegisterByConvention(services, assembly, "Service", ServiceLifetime.Scoped);
        RegisterByConvention(services, assembly, "Handler", ServiceLifetime.Scoped);
        return services;
    }

    private static void RegisterByConvention(IServiceCollection services, Assembly assembly, string suffix, ServiceLifetime lifetime)
    {
        var types = assembly.GetTypes()
            .Where(t => t.IsClass && !t.IsAbstract && t.Name.EndsWith(suffix))
            .ToList();

        foreach (var implementationType in types)
        {
            var interfaceType = implementationType.GetInterfaces().FirstOrDefault(i => i.Name == "I" + implementationType.Name);
            if (interfaceType != null)
            {
                services.Add(new ServiceDescriptor(interfaceType, implementationType, lifetime));
            }
        }
    }
}
EOL

cat <<EOL > src/Application/Common/CommonHandler.cs
using System;
using System.Net;
using Shared.Common;

namespace Application.Common;

public class CommonHandler
{
    public CommonHandler()
    {

    }

    protected ResponseModel SuccessResponse(HttpStatusCode statusCode = HttpStatusCode.OK)
    {
        return new ResponseModel
        {
            status = new StatusResponseModel
            {
                statusCode = statusCode
            }
        };
    }

    protected ResponseModel FailResponse(HttpStatusCode statusCode, string bizErrorCode)
    {
        return new ResponseModel
        {
            status = new StatusResponseModel
            {
                statusCode = statusCode,
                bizErrorCode = bizErrorCode
            }
        };
    }

    protected ResponseModel FailMessageResponse(HttpStatusCode statusCode, string bizErrorMessage)
    {
        return new ResponseModel
        {
            status = new StatusResponseModel
            {
                statusCode = statusCode,
                bizErrorMessage = bizErrorMessage
            }
        };
    }

    protected ResponseModel<T> SuccessResponse<T>(T data, HttpStatusCode statusCode = HttpStatusCode.OK)
    {
        return new ResponseModel<T>
        {
            status = new StatusResponseModel
            {
                statusCode = statusCode
            },
            data = data
        };
    }

    protected ResponseModel<T> FailResponse<T>(HttpStatusCode statusCode, string bizErrorCode)
    {
        return new ResponseModel<T>
        {
            status = new StatusResponseModel
            {
                statusCode = statusCode,
                bizErrorCode = bizErrorCode
            },
            data = default!
        };
    }

    protected ResponseModel<T> FailMessageResponse<T>(HttpStatusCode statusCode, string bizErrorMessage)
    {
        return new ResponseModel<T>
        {
            status = new StatusResponseModel
            {
                statusCode = statusCode,
                bizErrorMessage = bizErrorMessage
            },
            data = default!
        };
    }
}

public class CommonHandler<T> : CommonHandler
{
    public T _repository;
    public CommonHandler(T repository)
    {
        this._repository = repository;
    }
}
EOL

# Create subfolders in Domain and add .gitkeep

mkdir -p src/Domain/Common
mkdir -p src/Domain/Domains
mkdir -p src/Domain/Entities
mkdir -p src/Domain/Interfaces

PRES_SUBFOLDERS=(
  "Common"
  "Domains"
  "Entities"
  "Interfaces"
)

for sub in "${PRES_SUBFOLDERS[@]}"; do
  folder="src/Domain/$sub"
  mkdir -p "$folder"
  touch "$folder/.gitkeep"
done

# Create DependencyInjection.cs in Domain
cat <<EOL > src/Domain/DependencyInjection.cs
using Microsoft.Extensions.DependencyInjection;
using System.Reflection;

namespace Domain;

public static class DependencyInjection
{
    public static IServiceCollection AddDomain(this IServiceCollection services)
    {
        var assembly = Assembly.GetExecutingAssembly();

        // services.AddScoped<IDomainEventDispatcher, DomainEventDispatcher>();
        RegisterByConvention(services, assembly, "DomainService", ServiceLifetime.Scoped);

        return services;
    }

    private static void RegisterByConvention(IServiceCollection services, Assembly assembly, string suffix, ServiceLifetime lifetime)
    {
        var types = assembly.GetTypes()
            .Where(t => t.IsClass && !t.IsAbstract && t.Name.EndsWith(suffix))
            .ToList();

        foreach (var implementationType in types)
        {
            var interfaceType = implementationType.GetInterfaces().FirstOrDefault(i => i.Name == "I" + implementationType.Name);
            if (interfaceType != null)
            {
                services.Add(new ServiceDescriptor(interfaceType, implementationType, lifetime));
            }
        }
    }
}
EOL

cat <<EOL > src/Domain/Common/IEntity.cs
using System;

namespace Domain.Common;

public interface IEntity
{
    Guid id { get; set; }
}
EOL

cat <<EOL > src/Domain/Common/BaseEntity.cs
using System;
using MediatR;
using System.Collections.Generic;

namespace Domain.Common;

public abstract class BaseEntity : IEntity
{
    /// <summary>
    /// Unique identifier for the entity.
    /// </summary>
    public Guid id { get; set; } = Guid.NewGuid();

    /// <summary>
    /// Unique code for the entity.
    /// </summary>
    public string code { get; set; } = default!;

    private List<INotification> _domainEvents = new();
    public IReadOnlyCollection<INotification> DomainEvents => _domainEvents;

    protected void AddDomainEvent(INotification eventItem)
    {
        _domainEvents.Add(eventItem);
    }

    public void ClearDomainEvents()
    {
        _domainEvents.Clear();
    }
}
EOL

cat <<EOL > src/Domain/Common/AuditableEntity.cs
using System;

namespace Domain.Common;

public class AuditableEntity : BaseEntity
{
    /// <summary>
    /// Indicates whether the entity is currently active.
    /// </summary>
    public bool isActive { get; set; }

    /// <summary>
    /// The date and time when the entity was deactivated, if applicable.
    /// </summary>
    public DateTime? deactivatedAt { get; set; }

    /// <summary>
    /// Indicates whether the entity has been marked as deleted.
    /// </summary>
    public bool isDeleted { get; set; }

    /// <summary>
    /// The identifier of the user who deleted the entity, if applicable.
    /// </summary>
    public string? deletedById { get; set; }

    /// <summary>
    /// The date and time when the entity was deleted, if applicable.
    /// </summary>
    public DateTime? deletedAt { get; set; }

    /// <summary>
    /// The identifier of the user who created the entity.
    /// </summary>
    public string? createdById { get; set; }

    /// <summary>
    /// The date and time when the entity was created.
    /// </summary>
    public DateTime createdAt { get; set; }

    /// <summary>
    /// The identifier of the user who last updated the entity, if applicable.
    /// </summary>
    public string? updatedById { get; set; }

    /// <summary>
    /// The date and time when the entity was last updated, if applicable.
    /// </summary>
    public DateTime? updatedAt { get; set; }
}
EOL

# Create subfolders in Infrastructure and add .gitkeep
mkdir -p src/Infrastructure/Common
mkdir -p src/Infrastructure/Persistence
mkdir -p src/Infrastructure/Repositories

PRES_SUBFOLDERS=(
  "Common"
  "Persistence"
  "Repositories"
)

for sub in "${PRES_SUBFOLDERS[@]}"; do
  folder="src/Infrastructure/$sub"
  mkdir -p "$folder"
  touch "$folder/.gitkeep"
done

cat <<EOL > src/Infrastructure/Common/BaseRepository.cs
using System;
using Infrastructure.Persistence;

namespace Infrastructure.Common;

public class BaseRepository
{
    protected readonly AppDbContext _dbContext;
    public BaseRepository(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }
}

public class BaseRepository<T> : BaseRepository where T : class
{
    public BaseRepository(AppDbContext dbContext) : base(dbContext)
    {
    }
}
EOL

cat <<EOL > src/Infrastructure/Persistence/AppDbContext.cs
using Microsoft.EntityFrameworkCore;

namespace Infrastructure.Persistence;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Configure entity mappings here
    }
}
EOL

cat <<EOL > src/Infrastructure/DependencyInjection.cs
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Infrastructure.Persistence;
using System.Reflection;

namespace Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var assembly = Assembly.GetExecutingAssembly();

        var connectionString = configuration.GetConnectionString("DefaultConnection");
        services.AddDbContext<AppDbContext>(options => options.UseNpgsql(connectionString));

        RegisterByConvention(services, assembly, "Repository", ServiceLifetime.Scoped);
        RegisterByConvention(services, assembly, "Service", ServiceLifetime.Scoped);

        return services;
    }

    private static void RegisterByConvention(IServiceCollection services, Assembly assembly, string suffix, ServiceLifetime lifetime)
    {
        var types = assembly.GetTypes()
            .Where(t => t.IsClass && !t.IsAbstract && t.Name.EndsWith(suffix))
            .ToList();

        foreach (var implementationType in types)
        {
            var interfaceType = implementationType.GetInterfaces().FirstOrDefault(i => i.Name == "I" + implementationType.Name);
            if (interfaceType != null)
            {
                services.Add(new ServiceDescriptor(interfaceType, implementationType, lifetime));
            }
        }
    }
}
EOL

# Create subfolders in Migrator and add .gitkeep
mkdir -p src/Migrator/Common

PRES_SUBFOLDERS=(
  "Migrations"
  "Migrations/schema"
  "Migrations/data"
  "Migrations/view"
)

for sub in "${PRES_SUBFOLDERS[@]}"; do
  folder="src/Migrator/$sub"
  mkdir -p "$folder"
  touch "$folder/.gitkeep"
done

ENV_FILES=(
  "appsettings.Development.json"
  "appsettings.QA.json"
  "appsettings.UAT.json"
  "appsettings.SIT.json"
  "appsettings.Production.json"
)

for file in "${ENV_FILES[@]}"; do
  touch "src/Migrator/$file"
done

for file in "${ENV_FILES[@]}"; do
  cat > "src/Migrator/$file" <<EOL
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
EOL
done

rm -f src/Migrator/Program.cs

cat <<EOL > src/Migrator/Program.cs
using Microsoft.Extensions.Configuration;
using Migrator;

var config = new ConfigurationBuilder()
    .AddJsonFile("appsettings.json")
    .Build();

var connStr = config.GetConnectionString("DefaultConnection");

if (string.IsNullOrEmpty(connStr))
{
    Console.WriteLine("Error: Connection string 'DefaultConnection' is not found in the configuration.");
    return;
}

if (args.Length < 2)
{
    Console.WriteLine("Usage: dotnet run -- [up|down] [schema|seed]");
    return;
}

var direction = args[0];
var type = args[1];

var runner = new MigrationRunner(connStr);

// รอให้ MigrationRunner ทำงานเสร็จ
await runner.RunAsync(direction, type);
EOL

cat <<EOL > src/Migrator/MigrationRunner.cs
using System.Security.Cryptography;
using System.Text;
using Npgsql;

namespace Migrator;

public class MigrationRunner
{
    private readonly string _connStr;
    private readonly string _ipAddress;
    private readonly string _hostname;
    private readonly string _deviceId;
    private readonly string _locationName;
    private readonly string _latitude;
    private readonly string _longitude;

    public MigrationRunner(string connStr)
    {
        _connStr = connStr ?? throw new ArgumentNullException(nameof(connStr));
        _ipAddress = GetPublicIPAddress();
        _hostname = Environment.MachineName;
        _deviceId = GetDeviceId();


        using (var client = new HttpClient())
        {
            var json = client.GetStringAsync("http://ip-api.com/json").Result;
            var obj = System.Text.Json.JsonDocument.Parse(json).RootElement;
            _locationName = $"{obj.GetProperty("city").GetString()}, {obj.GetProperty("country").GetString()}";
            _latitude = obj.GetProperty("lat").GetDouble().ToString();
            _longitude = obj.GetProperty("lon").GetDouble().ToString();
        }
    }

    public async Task RunAsync(string direction, string type)
    {
        var folder = Path.Combine(Directory.GetCurrentDirectory(), "migrations", type);
        if (!Directory.Exists(folder))
        {
            Console.WriteLine($"❌ Folder not found: {folder}");
            return;
        }

        var files = Directory.GetFiles(folder, $"*.{direction}.sql");

        files = direction == "up"
            ? files.OrderBy(f => f).ToArray()
            : files.OrderByDescending(f => f).ToArray();

        await using var conn = new NpgsqlConnection(_connStr);
        await conn.OpenAsync();

        await EnsureMigrationsTableAsync(conn);
        await EnsureMigrationLogsTableAsync(conn);
        await EnsureMigrationChangesTableAsync(conn);

        foreach (var file in files)
        {
            var filename = Path.GetFileName(file);

            if (await HasAlreadyMigratedAsync(conn, filename, direction))
            {
                Console.WriteLine($"⏩ Already {direction}: {filename}");
                continue;
            }

            var beforeSnapshot = await GetSchemaSnapshotAsync(conn);

            var sql = await File.ReadAllTextAsync(file);

            await using var tx = await conn.BeginTransactionAsync();
            await using var cmd = new NpgsqlCommand(sql, conn, tx);
            await cmd.ExecuteNonQueryAsync();

            if (direction == "up")
            {
                await InsertMigrationAsync(conn, filename, direction);
            }
            else if (direction == "down")
            {
                var upFilename = filename.Replace(".down.sql", ".up.sql");
                await DeleteMigrationAsync(conn, upFilename, "up");
            }

            await tx.CommitAsync();

            var afterSnapshot = await GetSchemaSnapshotAsync(conn);

            var added = afterSnapshot.Except(beforeSnapshot);
            var removed = beforeSnapshot.Except(afterSnapshot);

            foreach (var item in added)
            {
                var parts = item.Split(':', 2);
                if (parts.Length == 2)
                {
                    await InsertSchemaChangeAsync(conn, filename, direction, parts[0], parts[1], "added");
                }
            }

            foreach (var item in removed)
            {
                var parts = item.Split(':', 2);
                if (parts.Length == 2)
                {
                    await InsertSchemaChangeAsync(conn, filename, direction, parts[0], parts[1], "removed");
                }
            }

            await InsertLogAsync(conn, filename, direction);

            Console.WriteLine($"✅ Success: {filename}");
        }
    }

    private static string GetLocalIPAddress()
    {
        try
        {
            using var socket = new System.Net.Sockets.Socket(System.Net.Sockets.AddressFamily.InterNetwork, System.Net.Sockets.SocketType.Dgram, 0);
            socket.Connect("8.8.8.8", 65530);
            var endPoint = socket.LocalEndPoint as System.Net.IPEndPoint;
            return endPoint?.Address.ToString() ?? "unknown";
        }
        catch
        {
            return "unknown";
        }
    }

    private static string GetPublicIPAddress()
    {
        try
        {
            using var client = new HttpClient();
            var ip = client.GetStringAsync("https://api.ipify.org").Result;
            return ip.Trim();
        }
        catch
        {
            return "unknown";
        }
    }

    private static string GetDeviceId()
    {
        var envDeviceId = Environment.GetEnvironmentVariable("DEVICE_ID");
        if (!string.IsNullOrEmpty(envDeviceId))
            return envDeviceId;

        using var sha256 = SHA256.Create();
        var machineName = Environment.MachineName;
        var hashed = sha256.ComputeHash(Encoding.UTF8.GetBytes(machineName));
        return BitConverter.ToString(hashed).Replace("-", "").Substring(0, 12);
    }

    private async Task EnsureMigrationsTableAsync(NpgsqlConnection conn)
    {
        await using var cmd = new NpgsqlCommand(@"
            CREATE TABLE IF NOT EXISTS __migrations (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                filename TEXT NOT NULL,
                direction TEXT NOT NULL,
                applied_at TIMESTAMP DEFAULT NOW()
            );
        ", conn);
        await cmd.ExecuteNonQueryAsync();
    }

    private async Task EnsureMigrationLogsTableAsync(NpgsqlConnection conn)
    {
        await using var cmd = new NpgsqlCommand(@"
            CREATE TABLE IF NOT EXISTS __migration_logs (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                filename TEXT NOT NULL,
                direction TEXT NOT NULL,
                executed_at TIMESTAMP DEFAULT NOW(),
                executed_by TEXT,
                ip_address TEXT,
                hostname TEXT,
                device_id TEXT,
                location_name TEXT,
                latitude TEXT,
                longitude TEXT
            );
        ", conn);
        await cmd.ExecuteNonQueryAsync();
    }

    private async Task EnsureMigrationChangesTableAsync(NpgsqlConnection conn)
    {
        await using var cmd = new NpgsqlCommand(@"
            CREATE TABLE IF NOT EXISTS __migration_changes (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                filename TEXT NOT NULL,
                direction TEXT NOT NULL,
                object_type TEXT NOT NULL,
                object_name TEXT NOT NULL,
                change_type TEXT NOT NULL,
                executed_at TIMESTAMP DEFAULT NOW()
            );
        ", conn);
        await cmd.ExecuteNonQueryAsync();
    }

    private async Task<HashSet<string>> GetSchemaSnapshotAsync(NpgsqlConnection conn)
    {
        var snapshot = new HashSet<string>();

        // Tables
        await using (var cmd = new NpgsqlCommand(@"
            SELECT schemaname || '.' || tablename AS full_table_name
            FROM pg_tables
            WHERE schemaname NOT IN ('pg_catalog', 'information_schema');
        ", conn))
        await using (var reader = await cmd.ExecuteReaderAsync())
        {
            while (await reader.ReadAsync())
            {
                var tableName = reader.GetString(0);
                snapshot.Add($"table:{tableName}");
            }
        }

        // Columns
        await using (var cmd = new NpgsqlCommand(@"
            SELECT table_schema || '.' || table_name || '.' || column_name AS full_column_name
            FROM information_schema.columns
            WHERE table_schema NOT IN ('pg_catalog', 'information_schema');
        ", conn))
        await using (var reader = await cmd.ExecuteReaderAsync())
        {
            while (await reader.ReadAsync())
            {
                var columnName = reader.GetString(0);
                snapshot.Add($"column:{columnName}");
            }
        }

        // Indexes
        await using (var cmd = new NpgsqlCommand(@"
            SELECT schemaname || '.' || tablename || '.' || indexname AS full_index_name
            FROM pg_indexes
            WHERE schemaname NOT IN ('pg_catalog', 'information_schema');
        ", conn))
        await using (var reader = await cmd.ExecuteReaderAsync())
        {
            while (await reader.ReadAsync())
            {
                var indexName = reader.GetString(0);
                snapshot.Add($"index:{indexName}");
            }
        }

        return snapshot;
    }

    private async Task InsertSchemaChangeAsync(NpgsqlConnection conn, string filename, string direction, string objectType, string objectName, string changeType)
    {
        await using var cmd = new NpgsqlCommand(@"
            INSERT INTO __migration_changes (
                filename, direction, object_type, object_name, change_type
            ) VALUES (
                @filename, @direction, @object_type, @object_name, @change_type
            );
        ", conn);

        cmd.Parameters.AddWithValue("filename", filename);
        cmd.Parameters.AddWithValue("direction", direction);
        cmd.Parameters.AddWithValue("object_type", objectType);
        cmd.Parameters.AddWithValue("object_name", objectName);
        cmd.Parameters.AddWithValue("change_type", changeType);

        await cmd.ExecuteNonQueryAsync();
    }

    private async Task<bool> HasAlreadyMigratedAsync(NpgsqlConnection conn, string filename, string direction)
    {
        await using var cmd = new NpgsqlCommand(@"
            SELECT COUNT(1) FROM __migrations
            WHERE filename = @filename AND direction = @direction;
        ", conn);

        cmd.Parameters.AddWithValue("filename", filename);
        cmd.Parameters.AddWithValue("direction", direction);

        var result = await cmd.ExecuteScalarAsync();
        return Convert.ToInt32(result) > 0;
    }

    private async Task InsertMigrationAsync(NpgsqlConnection conn, string filename, string direction)
    {
        await using var cmd = new NpgsqlCommand(@"
            INSERT INTO __migrations (filename, direction)
            VALUES (@filename, @direction);
        ", conn);

        cmd.Parameters.AddWithValue("filename", filename);
        cmd.Parameters.AddWithValue("direction", direction);

        await cmd.ExecuteNonQueryAsync();
    }

    private async Task DeleteMigrationAsync(NpgsqlConnection conn, string filename, string direction)
    {
        await using var cmd = new NpgsqlCommand(@"
            DELETE FROM __migrations
            WHERE filename = @filename AND direction = @direction;
        ", conn);

        cmd.Parameters.AddWithValue("filename", filename);
        cmd.Parameters.AddWithValue("direction", direction);

        await cmd.ExecuteNonQueryAsync();
    }

    private async Task InsertLogAsync(NpgsqlConnection conn, string filename, string direction)
    {
        await using var cmd = new NpgsqlCommand(@"
            INSERT INTO __migration_logs (
                filename, direction, executed_by, ip_address, hostname, device_id, location_name, latitude, longitude
            ) VALUES (
                @filename, @direction, @executed_by, @ip_address, @hostname, @device_id, @location_name, @latitude, @longitude
            );
        ", conn);

        cmd.Parameters.AddWithValue("filename", filename);
        cmd.Parameters.AddWithValue("direction", direction);
        cmd.Parameters.AddWithValue("executed_by", Environment.UserName);
        cmd.Parameters.AddWithValue("ip_address", _ipAddress);
        cmd.Parameters.AddWithValue("hostname", _hostname);
        cmd.Parameters.AddWithValue("device_id", _deviceId);
        cmd.Parameters.AddWithValue("location_name", _locationName);
        cmd.Parameters.AddWithValue("latitude", _latitude);
        cmd.Parameters.AddWithValue("longitude", _longitude);

        await cmd.ExecuteNonQueryAsync();
    }
}
EOL

mkdir -p src/Shared/Common
mkdir -p src/Shared/Configurations
mkdir -p src/Shared/DTOs
mkdir -p src/Shared/Extensions

PRES_SUBFOLDERS=(
  "Common"
  "Configurations"
  "DTOs"
  "Extensions"
)

for sub in "${PRES_SUBFOLDERS[@]}"; do
  folder="src/Shared/$sub"
  mkdir -p "$folder"
  touch "$folder/.gitkeep"
done

cat <<EOL > src/Shared/Common/HeaderModel.cs
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
EOL

cat <<EOL > src/Shared/Common/ResponseModel.cs
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

            return Regex.Replace(name, "(?<!^)([A-Z])", " $1");
        }
    }
    public string? bizErrorCode { get; set; } = default!;
    public string? bizErrorMessage { get; set; } = default!;
    public DateTime timestamp { get; set; }
}
EOL

cat <<EOL > src/Shared/Configurations/AppSettings.cs
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
EOL

cat <<EOL > src/Shared/Extensions/ErrorHandlerExtension.cs
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
EOL

cat <<EOL > src/Shared/DTOs/FileDTO.cs
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

EOL

echo "✅ Solution structure created successfully!"

cd $SOLUTION_NAME || exit 1

echo "🧹 Cleaning solution..."
dotnet clean

echo "🏗 Building solution..."
dotnet build

echo "✅ Build finished!"