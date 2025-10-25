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
