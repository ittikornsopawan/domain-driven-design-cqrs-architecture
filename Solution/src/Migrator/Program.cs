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
