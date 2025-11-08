#!/usr/bin/env bash
# --------------------------------------------
# Clean Architecture Shell Generator (.NET 9)
# Usage: ./init.sh <SolutionName>
# --------------------------------------------

if [ -z "$1" ]; then
  echo "❌ Please provide a solution name: ./init.sh Products"
  exit 1
fi

set -e

# ------------------------------
# Pre-check: OS + .NET SDK
# ------------------------------

OS_TYPE="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_TYPE="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
    OS_TYPE="windows"
fi
echo "🔍 Detected OS: $OS_TYPE"

if ! command -v dotnet &> /dev/null; then
    echo "⚠️  .NET SDK not found! Please install .NET SDK first."
    exit 1
else
    DOTNET_VERSION=$(dotnet --version)
    echo "✅ .NET SDK detected: $DOTNET_VERSION"
fi

echo "✅ Pre-check passed! Proceeding with solution initialization..."

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
    src/Infrastructure/Infrastructure.csproj \
    src/Shared/Shared.csproj

dotnet add src/Application/Application.csproj reference \
    src/Domain/Domain.csproj \
    src/Infrastructure/Infrastructure.csproj \
    src/Shared/Shared.csproj

dotnet add src/Domain/Domain.csproj reference \
    src/Shared/Shared.csproj

dotnet add src/Infrastructure/Infrastructure.csproj reference \
    src/Domain/Domain.csproj \
    src/Shared/Shared.csproj

dotnet add test/Application.Test/Application.Test.csproj reference \
    src/Application/Application.csproj \
    src/Shared/Shared.csproj

dotnet add test/Domain.Test/Domain.Test.csproj reference \
    src/Domain/Domain.csproj \
    src/Shared/Shared.csproj

set -e

echo "🔍 Checking .NET SDK version..."
DOTNET_VERSION=$(dotnet --version)
echo "✅ Detected .NET SDK version: $DOTNET_VERSION"

# NuGet packages per project
PACKAGES=(
  "src/Presentation:AutoMapper"
  "src/Presentation:AutoMapper.Extensions.Microsoft.DependencyInjection"
  "src/Presentation:FluentValidation"
  "src/Presentation:FluentValidation.DependencyInjectionExtensions"
  "src/Presentation:MediatR"
  "src/Presentation:Microsoft.AspNetCore.OpenApi"
  "src/Presentation:Microsoft.EntityFrameworkCore"
  "src/Presentation:Microsoft.EntityFrameworkCore.Design"
  "src/Presentation:Microsoft.EntityFrameworkCore.Relational"
  "src/Presentation:Npgsql.EntityFrameworkCore.PostgreSQL"
  "src/Presentation:Serilog.AspNetCore"
  "src/Presentation:Serilog.Settings.Configuration"
  "src/Presentation:Swashbuckle.AspNetCore"

  "src/Application:AutoMapper"
  "src/Application:AutoMapper.Extensions.Microsoft.DependencyInjection"
  "src/Application:FluentValidation"
  "src/Application:FluentValidation.DependencyInjectionExtensions"
  "src/Application:MediatR"

  "src/Domain:MediatR"
  "src/Domain:Microsoft.Extensions.DependencyInjection"

  "src/Infrastructure:AutoMapper"
  "src/Infrastructure:AutoMapper.Extensions.Microsoft.DependencyInjection"
  "src/Infrastructure:MediatR"
  "src/Infrastructure:Microsoft.EntityFrameworkCore"
  "src/Infrastructure:Microsoft.EntityFrameworkCore.Design"
  "src/Infrastructure:Microsoft.EntityFrameworkCore.Relational"
  "src/Infrastructure:Microsoft.Extensions.DependencyInjection"
  "src/Infrastructure:Npgsql.EntityFrameworkCore.PostgreSQL"

  "src/Migrator:Microsoft.Extensions.Configuration"
  "src/Migrator:Microsoft.Extensions.Configuration.Binder"
  "src/Migrator:Microsoft.Extensions.Configuration.Json"
  "src/Migrator:Microsoft.Extensions.DependencyInjection"
  "src/Migrator:Microsoft.Extensions.Logging"
  "src/Migrator:Npgsql"
)

echo "📦 Installing latest NuGet packages..."

for entry in "${PACKAGES[@]}"; do
    IFS=":" read -r proj pkg <<< "$entry"
    echo "🔄 Installing latest version of $pkg in $proj..."
    dotnet add "$proj" package "$pkg" --version "*" || {
        echo "⚠️ Failed to install $pkg in $proj — skipping..."
    }
done

echo "✅ All packages installed with latest versions!"

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
mkdir -p src/Presentation/Controllers

PRES_SUBFOLDERS=(
  "Common"
  "Common/Attributes"
  "Common/Behaviors"
  "Common/Extensions"
  "Logs"
  "Models"
  "Requests"
  "Resources"
  "Controllers"
)

for sub in "${PRES_SUBFOLDERS[@]}"; do
  folder="src/Presentation/$sub"
  mkdir -p "$folder"
#   touch "$folder/.gitkeep"
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
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=product_db;Username=postgres;Password=password1234"
  },
  "Redis": {
    "Host": "localhost",
    "Port": 6379,
    "Password": "password1234"
  },
  "Encryption": {
    "Key": "d4b9c21ee8f35a16ec2d7166c5f429e4e1aef1fc2a184e6b1fb5cf1e95a2782e",
    "IV": "9d46d95b2f37c5cc983b298bb87c6f89"
  },
  "DbEncryption": {
    "Key": "f7a3c87e5bd4126e9a6a15ef91b49b0df17c9e86a1f25e3c8d4f03dcbbab12e0",
    "IV": "7c2e91a4b5d3fa87e9c4c128a97e38cb"
  },
  "Serilog": {
    "WriteTo": [
      {
        "Name": "File",
        "Args": {
          "path": "Logs/dev-log-.txt",
          "rollingInterval": "Day",
          "outputTemplate": "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}"
        }
      }
    ]
  },
  "Token": {
    "ExpireBufferMinutes": 15,
    "AccessTokenExpirationMinutes": 60,
    "RefreshTokenExpirationDays": 30
  },
  "Pagination": {
    "DefaultPageSize": 20
  }
}
EOL
done

rm -f src/Presentation/Program.cs

cat <<EOL > src/Presentation/Program.cs
using System.Net;
using Microsoft.OpenApi.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

using Microsoft.Extensions.Options;

using Serilog;
using FluentValidation;
using MediatR;

using Presentation.Common.Behaviors;

using Application;
using Domain;

using Infrastructure;
using Infrastructure.Persistence;

using Shared.Configurations;
using Shared.Common;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
    .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json", optional: true, reloadOnChange: true)
    .AddEnvironmentVariables();

builder.Services.AddDbContext<AppDbContext>(options =>
    options
        .UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"))
        .EnableSensitiveDataLogging()
        .LogTo(Console.WriteLine, LogLevel.Information)
);

builder.Services
    .AddApplication()
    .AddDomain()
    .AddInfrastructure(builder.Configuration);

// Dynamically register interface-implementation pairs across assemblies (e.g., IMemberRepository -> MemberRepository)
var loadedAssemblies = AppDomain.CurrentDomain.GetAssemblies()
    .Where(x => !x.IsDynamic && !string.IsNullOrEmpty(x.FullName))
    .ToList();

var projectAssemblies = loadedAssemblies
    .Where(x => x.FullName!.StartsWith("Microservices"))
    .ToList();

var allInterfaces = projectAssemblies
    .SelectMany(x => x.GetTypes())
    .Where(x => x.IsInterface)
    .ToList();

var allImplementations = projectAssemblies
    .SelectMany(x => x.GetTypes())
    .Where(x => x.IsClass && !x.IsAbstract && !x.IsGenericTypeDefinition)
    .ToList();

foreach (var impl in allImplementations)
{
    var iface = allInterfaces.FirstOrDefault(x => x.Name == $"I{impl.Name}");
    if (iface != null)
    {
        builder.Services.AddScoped(iface, impl);
        Console.WriteLine($"[DI] Registered {iface.FullName} => {impl.FullName}");
    }
}

builder.Services.AddAutoMapper(AppDomain.CurrentDomain.GetAssemblies());
builder.Services.Configure<AppSettings>(builder.Configuration);
builder.Services.AddSingleton(resolver =>
    resolver.GetRequiredService<IOptions<AppSettings>>().Value);

builder.Host.UseSerilog((context, configuration) => configuration.ReadFrom.Configuration(context.Configuration));

builder.Services.AddControllers();
builder.Services.AddAuthorization();

builder.Services.Configure<ApiBehaviorOptions>(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var response = new ResponseModel
        {
            status = new StatusResponseModel
            {
                statusCode = HttpStatusCode.BadRequest,
                timestamp = DateTime.UtcNow
            }
        };

        return new BadRequestObjectResult(response);
    };
});

var assemblies = AppDomain.CurrentDomain.GetAssemblies();

builder.Services.AddValidatorsFromAssemblies(assemblies);
builder.Services.AddTransient(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));

// Add Swagger/OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Loyalty Program", Version = "v1" });

    var securityScheme = new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter 'Bearer' [space] and then your valid token."
    };

    c.AddSecurityDefinition("Bearer", securityScheme);

    var securityRequirement = new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    };

    c.AddSecurityRequirement(securityRequirement);
});  // เพิ่ม Swagger

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseSerilogRequestLogging();

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

try
{
    Log.Information("Starting Products API");
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Product API terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}

EOL

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

cat <<EOL > src/Presentation/Controllers/BaseController.cs
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
EOL


mkdir -p src/Application/Common

PRES_SUBFOLDERS=(
  "Common"
)

for sub in "${PRES_SUBFOLDERS[@]}"; do
  folder="src/Application/$sub"
  mkdir -p "$folder"
#   touch "$folder/.gitkeep"
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
#   touch "$folder/.gitkeep"
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
#   touch "$folder/.gitkeep"
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
#   touch "$folder/.gitkeep"
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
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=product_db;Username=postgres;Password=password1234"
  },
  "Redis": {
    "Host": "localhost",
    "Port": 6379,
    "Password": "password1234"
  },
  "Encryption": {
    "Key": "d4b9c21ee8f35a16ec2d7166c5f429e4e1aef1fc2a184e6b1fb5cf1e95a2782e",
    "IV": "9d46d95b2f37c5cc983b298bb87c6f89"
  },
  "DbEncryption": {
    "Key": "f7a3c87e5bd4126e9a6a15ef91b49b0df17c9e86a1f25e3c8d4f03dcbbab12e0",
    "IV": "7c2e91a4b5d3fa87e9c4c128a97e38cb"
  },
  "Serilog": {
    "WriteTo": [
      {
        "Name": "File",
        "Args": {
          "path": "Logs/dev-log-.txt",
          "rollingInterval": "Day",
          "outputTemplate": "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}"
        }
      }
    ]
  },
  "Token": {
    "ExpireBufferMinutes": 15,
    "AccessTokenExpirationMinutes": 60,
    "RefreshTokenExpirationDays": 30
  },
  "Pagination": {
    "DefaultPageSize": 20
  }
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
#   touch "$folder/.gitkeep"
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

# ------------------------------
# Check .NET SDK version
# ------------------------------
DOTNET_VERSION=$(dotnet --version)
STABLE_VERSION_REGEX="^[0-9]+\.[0-9]+\.[0-9]+$"

if [[ ! $DOTNET_VERSION =~ $STABLE_VERSION_REGEX ]]; then
    echo "⚠️ Detected .NET SDK version: $DOTNET_VERSION"
    echo "⚠️ Warning: This might not be a stable version. Consider using a stable .NET SDK."
else
    echo "✅ .NET SDK version $DOTNET_VERSION is stable."
fi

# ------------------------------
# Define Projects
# ------------------------------
PROJECTS=(
    "src/Migrator/Migrator.csproj"
    "src/Shared/Shared.csproj"
    "src/Infrastructure/Infrastructure.csproj"
    "src/Domain/Domain.csproj"
    "src/Application/Application.csproj"
    "src/Presentation/Presentation.csproj"
)

echo "🔄 Checking NuGet packages for all projects..."

for proj in "${PROJECTS[@]}"; do
    echo "📦 Project: $proj"
    
    OUTDATED=$(dotnet list "$proj" package --outdated)

    if [[ $OUTDATED == *"No outdated packages"* ]]; then
        echo "✅ No updates required for $proj"
    else
        echo "⚠️ Found outdated packages in $proj"
        echo "$OUTDATED"
        
        while read -r line; do
            PKG=$(echo $line | awk '{print $1}')
            
            if [[ $PKG != ">" && $PKG != "Package" && -n $PKG ]]; then
                echo "🔄 Upgrading $PKG in $proj..."
                dotnet add "$proj" package "$PKG" --prerelease
            fi
        done <<< "$(echo "$OUTDATED" | tail -n +3)"
    fi
done

echo "✅ All projects processed!"

echo "✅ Build finished!"