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
