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
