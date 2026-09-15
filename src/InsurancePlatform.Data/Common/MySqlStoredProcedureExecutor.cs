using System.Data;
using InsurancePlatform.Domain.Common;
using Microsoft.Extensions.Configuration;
using MySqlConnector;

namespace InsurancePlatform.Data.Common;


public class MySqlStoredProcedureExecutor : IStoredProcedureExecutor
{
    private readonly string _connectionString;

    public MySqlStoredProcedureExecutor(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException(
                "Connection string 'DefaultConnection' is not configured in appsettings.json.");
    }

    public async Task<StoredProcResult> ExecuteAsync(string procedureName,IReadOnlyList<MySqlParameter> parameters)
    {
        await using var connection = new MySqlConnection(_connectionString);
        await connection.OpenAsync();

        await using var command = BuildCommand(connection, procedureName, parameters);
        await command.ExecuteNonQueryAsync();

        return ReadEnvelope(command);
    }

    public async Task<StoredProcResult<List<T>>> ExecuteQueryAsync<T>(string procedureName,IReadOnlyList<MySqlParameter> parameters,Func<MySqlDataReader, T> map)
    {
        await using var connection = new MySqlConnection(_connectionString);
        await connection.OpenAsync();

        await using var command = BuildCommand(connection, procedureName, parameters);

        var rows = new List<T>();
        await using (var reader = await command.ExecuteReaderAsync())
        {
            while (await reader.ReadAsync())
            {
                rows.Add(map(reader));
            }
        }

        var envelope = ReadEnvelope(command);
        return new StoredProcResult<List<T>>
        {
            ResultCode = envelope.ResultCode,
            ResultMessage = envelope.ResultMessage,
            Data = rows
        };
    }

    public async Task<StoredProcResult<T?>> ExecuteQuerySingleAsync<T>(string procedureName,IReadOnlyList<MySqlParameter> parameters,Func<MySqlDataReader,T> map)
    {
        await using var connection = new MySqlConnection(_connectionString);
        await connection.OpenAsync();

        await using var command = BuildCommand(connection, procedureName, parameters);

        T? row = default;
        await using (var reader = await command.ExecuteReaderAsync())
        {
            if (await reader.ReadAsync())
            {
                row = map(reader);
            }
        }

        var envelope = ReadEnvelope(command);
        return new StoredProcResult<T?>
        {
            ResultCode = envelope.ResultCode,
            ResultMessage = envelope.ResultMessage,
            Data = row
        };
    }

    public async Task<StoredProcResult<T?>> ExecuteQuerySingleWithChildrenAsync<T, TChild>(
        string procedureName,
        IReadOnlyList<MySqlParameter> parameters,
        Func<MySqlDataReader, T> mapPrimary,
        Func<MySqlDataReader, TChild> mapChild,
        Action<T, List<TChild>> attachChildren) where T : class
    {
        await using var connection = new MySqlConnection(_connectionString);
        await connection.OpenAsync();

        await using var command = BuildCommand(connection, procedureName, parameters);

        T? primary = null;
        var children = new List<TChild>();

        await using (var reader = await command.ExecuteReaderAsync())
        {
            if (await reader.ReadAsync())
            {
                primary = mapPrimary(reader);
            }

            // Second SELECT in the proc body - moves the same reader onto
            // it. If the primary row wasn't found, the proc's second
            // SELECT still runs and returns zero rows (it's an
            // unconditional query keyed on the same p_purchase_id), so this
            // is safe to call either way.
            if (await reader.NextResultAsync())
            {
                while (await reader.ReadAsync())
                {
                    children.Add(mapChild(reader));
                }
            }
        }

        if (primary is not null)
        {
            attachChildren(primary, children);
        }

        var envelope = ReadEnvelope(command);
        return new StoredProcResult<T?>
        {
            ResultCode = envelope.ResultCode,
            ResultMessage = envelope.ResultMessage,
            Data = primary
        };
    }

    private static MySqlCommand BuildCommand( MySqlConnection connection,string procedureName,IReadOnlyList<MySqlParameter> parameters)
    {
        var command = connection.CreateCommand();
        command.CommandType = CommandType.StoredProcedure;
        command.CommandText = procedureName;

        foreach (var parameter in parameters)
        {
            command.Parameters.Add(parameter);
        }

        EnsureEnvelopeParameters(command);

        return command;
    }

    private static void EnsureEnvelopeParameters(MySqlCommand command)
    {
        // MySqlConnector calls stored procedures POSITIONALLY - it builds
        // "CALL proc(@p1, @p2, ...)" using command.Parameters in the exact
        // order they were added, and matches the returned OUT values back
        // by that same position. It does NOT look up the procedure's real
        // signature and match by name. Every proc in this project declares
        // o_result_code/o_result_message immediately after the IN params
        // and BEFORE any proc-specific OUT params (o_otp_id, o_user_id,
        // etc. - see the .sql files), so these two have to be INSERTED at
        // that same position here, not appended after whatever
        // proc-specific OUT params a repository already added. Appending
        // would silently shift every OUT parameter one or two slots out of
        // sync with what the real procedure returns - which is exactly the
        // bug this fixes (o_user_id was receiving o_result_code's value,
        // o_client_id was receiving the o_result_message string, etc.).
        var insertIndex = command.Parameters.Count;
        for (var i = 0; i < command.Parameters.Count; i++)
        {
            if (command.Parameters[i].Direction == ParameterDirection.Output)
            {
                insertIndex = i;
                break;
            }
        }

        if (!command.Parameters.Contains("o_result_code"))
        {
            command.Parameters.Insert(insertIndex, new MySqlParameter("o_result_code", MySqlDbType.Int32)
            {
                Direction = ParameterDirection.Output
            });
            insertIndex++;
        }

        if (!command.Parameters.Contains("o_result_message"))
        {
            command.Parameters.Insert(insertIndex, new MySqlParameter("o_result_message", MySqlDbType.VarChar, 500)
            {
                Direction = ParameterDirection.Output
            });
        }
    }

    private static StoredProcResult ReadEnvelope(MySqlCommand command)
    {
        var resultCodeValue = command.Parameters["o_result_code"].Value;
        var resultMessageValue = command.Parameters["o_result_message"].Value;

        var resultCode = resultCodeValue is null or DBNull
            ? ResultCodes.UnexpectedError
            : Convert.ToInt32(resultCodeValue);

        return new StoredProcResult
        {
            ResultCode = resultCode,
            ResultMessage = resultMessageValue as string ?? string.Empty
        };
    }
}
