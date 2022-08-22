using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using DbUp;
using DbUp.Helpers;

namespace Migrator
{
    /// <summary>
    /// The result of executing a database migration
    /// </summary>
    public class MigratorResult
    {
        /// <summary>
        /// If the migration was successful
        /// </summary>
        public bool IsSuccessful { get; set; }
        /// <summary>
        /// If it wasn't successful then the error that was received.
        /// </summary>
        public string Errors { get; set; }
    }

    /// <summary>
    /// Orchestrates database migrations from the filesystem via a folder/file convention.
    /// </summary>
    public static class Migrator
    {
        /// <summary>
        /// Migrates a folder into a SQL Connection - separating:
        ///  * Migrations (which are journaled so they run once only)
        ///  * Functions
        ///  * Procedures; and
        ///  * Views
        ///
        /// The first is based on executing each file in alphabetical order and using the file name as a persistent journal identifier.
        /// The latter 3 are based on a folder convention with the same name and one file per item.
        /// </summary>
        /// <param name="rootFolder">The root folder with the various convention sub folders</param>
        /// <param name="connection">An open SQL connection to the database to migrate as an identity with DDL permissions</param>
        /// <returns>The result</returns>
        public static MigratorResult Migrate(string rootFolder, string connectionString, Hashtable migrationVariables)
        {
            var migrationsFolder = Path.Combine(rootFolder, "Migrations");
            if (Directory.Exists(migrationsFolder))
            {
                var result = MigrateSingleFolder(migrationsFolder, connectionString, runAlways: false, variables: migrationVariables);
                if (!result.IsSuccessful)
                    return result;
            }

            var functionsFolder = Path.Combine(rootFolder, "Functions");
            if (Directory.Exists(functionsFolder))
            {
                var result = MigrateSingleFolder(functionsFolder, connectionString, runAlways: true);
                if (!result.IsSuccessful)
                    return result;
            }

            var proceduresFolder = Path.Combine(rootFolder, "Procedures");
            if (Directory.Exists(proceduresFolder))
            {
                var result = MigrateSingleFolder(proceduresFolder, connectionString, runAlways: true);
                if (!result.IsSuccessful)
                    return result;
            }

            var viewsFolder = Path.Combine(rootFolder, "Views");
            if (Directory.Exists(viewsFolder))
            {
                var result = MigrateSingleFolder(viewsFolder, connectionString, runAlways: true);
                if (!result.IsSuccessful)
                    return result;
            }

            return new MigratorResult { IsSuccessful = true };
        }

        private static MigratorResult MigrateSingleFolder(string folder, string connectionString, bool runAlways, Hashtable variables = null)
        {
            Console.Out.WriteLine($"Migrating {folder}...");

            var upgraderConfig = DeployChanges.To
                .SqlDatabase(connectionString)
                .WithScriptsFromFileSystem(folder);

            if (runAlways)
                upgraderConfig = upgraderConfig.JournalTo(new NullJournal());

            if (variables != null)
            {
                Console.Out.WriteLine($"Using variables {JsonSerializer.Serialize(variables, new JsonSerializerOptions {WriteIndented = true})}");
                upgraderConfig = upgraderConfig.WithVariables(variables.ToDictionary());
            }

            var upgrader = upgraderConfig
                .WithTransaction()
                .LogToConsole()
                .Build();

            var result = upgrader.PerformUpgrade();

            return new MigratorResult
            {
                IsSuccessful = result.Successful,
                Errors = result.Error?.ToString(),
            };
        }
    }
}