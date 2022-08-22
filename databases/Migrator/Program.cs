using System;
using System.Collections;
using System.Collections.Generic;
using DbUp;

namespace Migrator
{
    /// <summary>
    /// Runs migrations against local database; use Migrator class directly for non-local.
    /// Assumes you have SQL Express 2019+ installed locally.
    /// </summary>
    class Program
    {
        static int Main(string[] args)
        {
            var ok = MigrateLocal("ADP_Config");

            if (ok)
            {
                ok = MigrateLocal("ADP_Stage");
            }

            return ok ? 0 : -1;
        }

        static bool MigrateLocal(string database)
        {
            var connectionString = $"Server=.\\SQLEXPRESS01; Database={database}; Trusted_connection=true";
            EnsureDatabase.For.SqlDatabase(connectionString);
            var result = Migrator.Migrate($"..\\..\\..\\..\\{database}", connectionString, new Hashtable()
            {
                {"LogicAppSendEmailUrl", "_LogicAppSendEmailUrl_"},
                {"LogicAppScaleVMUrl", "_LogicAppScaleVMUrl_"},
                {"LogicAppScaleSQLUrl", "_LogicAppScaleSQLUrl_"},
                {"KeyVaultName", "_KeyVaultName_"},
                {"DataLakeStorageEndpoint", "_DataLakeStorageEndpoint_"},
                {"DataLakeDateMask", "_DataLakeDateMask_"},
                {"DatabricksWorkspaceURL", "_DatabricksWorkspaceURL_"},
                {"DatabricksStandardClusterID", "_DatabricksStandardClusterID_"},
                {"WebAppAdminUserID", "_WebAppAdminUserID_"},
                {"WebAppAdminUsername", "_WebAppAdminUsername_"},
                {"WebAppAdminUPN", "_WebAppAdminUPN_"},
                {"StageDatabaseName", "_StageDatabaseName_"}
            });

            if (!result.IsSuccessful)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine(result.Errors);
                Console.ResetColor();
                return false;
            }

            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("Success!");
            Console.ResetColor();
            return true;
        }
    }
}
