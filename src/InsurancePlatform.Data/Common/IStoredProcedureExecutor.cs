using InsurancePlatform.Domain.Common;
using MySqlConnector;

namespace InsurancePlatform.Data.Common;


public interface IStoredProcedureExecutor
{
   
    Task<StoredProcResult> ExecuteAsync(string procedureName, IReadOnlyList<MySqlParameter> parameters);

    
    Task<StoredProcResult<List<T>>> ExecuteQueryAsync<T>(string procedureName,IReadOnlyList<MySqlParameter> parameters,Func<MySqlDataReader, T> map);

    Task<StoredProcResult<T?>> ExecuteQuerySingleAsync<T>(string procedureName,IReadOnlyList<MySqlParameter> parameters,Func<MySqlDataReader, T> map);

    // For the one proc shape in this project that returns TWO result sets
    // from a single CALL - usp_Purchase_GetById (the purchase row, then any
    // VehiclePurchaseSnapshot rows for a Motor purchase). Reads the first
    // result set as at most one row (mapPrimary), advances to the second
    // result set with reader.NextResultAsync(), reads every row there
    // (mapChildren), then hands both to attachChildren so the caller's map
    // function decides where the children get attached on the primary
    // object (e.g. a Snapshot property) - kept generic rather than
    // hard-coded to Purchase/VehiclePurchaseSnapshot in case another
    // multi-result-set proc shows up later.
    Task<StoredProcResult<T?>> ExecuteQuerySingleWithChildrenAsync<T, TChild>(
        string procedureName,
        IReadOnlyList<MySqlParameter> parameters,
        Func<MySqlDataReader, T> mapPrimary,
        Func<MySqlDataReader, TChild> mapChild,
        Action<T, List<TChild>> attachChildren) where T : class;
}
