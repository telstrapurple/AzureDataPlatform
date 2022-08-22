using NUnit.Framework;
using ADPConfigurator.Domain.Models;
using ADPConfigurator.Domain;
using System.Collections.Generic;

namespace TestDomain
{
    public class TestTaskDiff
    {
        public static TaskProperty CreateTaskProperty(string taskTypeName = "oldTaskTypeName", string prefix = "old")
        {
            var type = new TaskPropertyType
            {
                TaskPropertyTypeName = taskTypeName
            };
            return new TaskProperty
            {
                TaskPropertyType = type,
                TaskPropertyValue = $"{prefix}Value",
                DeletedIndicator = false,
            };
        }

        public static Connection CreateConnection(string prefix = "old")
        {
            return new Connection
            {
                ConnectionName = $"{prefix}Connection"
            };
        }

        public static FileColumnMapping CreateFileColumnMapping(string prefix = "old")
        {
            return new FileColumnMapping
            {
                SourceColumnName = $"{prefix}Source",
                TargetColumnName = $"{prefix}oldTarget",
                DataLength = "1",
                FileInterimDataType = new FileInterimDataType
                {
                    FileInterimDataTypeName = $"{prefix}TypeName"
                }
            };
        }

        public static Task CreateTask(string prefix = "old")
        {
            var properties = new List<TaskProperty>
            {
                CreateTaskProperty("oldTaskTypeName", prefix)
            };

            var fileMappings = new List<FileColumnMapping>
            {
                CreateFileColumnMapping(prefix),
            };

            var taskType = new TaskType
            {
                TaskTypeName = $"{prefix}TaskTypeName"
            };

            return new Task
            {
                TaskName = $"{prefix}Name",
                TaskDescription = $"{prefix}Description",
                TaskType = taskType,
                SourceConnection = CreateConnection(prefix),
                Etlconnection = CreateConnection(prefix),
                StageConnection = CreateConnection(prefix),
                TargetConnection = CreateConnection(prefix),
                EnabledIndicator = true,
                DeletedIndicator = false,
                TaskOrderId = 1,
                TaskProperty = properties,
                FileColumnMapping = fileMappings,
            };
        }

        [Test]
        public void CreatesAValidDiff()
        {
            var diff = new EntityDiff();
            var left = CreateTask();
            var right = CreateTask("new");
            left.Diff(diff, right);

            Assert.AreEqual(
@"Description: oldDescription => newDescription
Type: oldTaskTypeName => newTaskTypeName
Source Connection: oldConnection => newConnection
ETL Connection: oldConnection => newConnection
Staging Connection: oldConnection => newConnection
Target Connection: oldConnection => newConnection
oldTaskTypeName: oldValue => newValue
File column mappings will update. Can't preview changes.
", diff.ToString());
        }
    }
}
