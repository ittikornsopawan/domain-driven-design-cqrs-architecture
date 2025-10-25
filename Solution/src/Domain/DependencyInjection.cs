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
