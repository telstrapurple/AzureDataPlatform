using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System;
using System.Collections.Generic;

// ReSharper disable once CheckNamespace - must match other 'side' of the partial class
namespace ADPConfigurator.Domain.Models
{
    public partial class Task
    {
        [NotMapped]
        public bool Enabled
        {
            get
            {
                // Enabled has default value == true
                return EnabledIndicator.HasValue ? EnabledIndicator.Value : true;
            }
            set
            {
                EnabledIndicator = value;
            }
        }

        public void Diff(EntityDiff diff, Task right)
        {
            var left = this;
            diff.AddLine("Description", left?.TaskDescription, right?.TaskDescription);
            diff.AddLine("Type", left?.TaskType?.TaskTypeName, right?.TaskType.TaskTypeName);
            diff.AddLine("Source Connection", left?.SourceConnection?.ConnectionName, right?.SourceConnection?.ConnectionName);
            diff.AddLine("ETL Connection", left?.Etlconnection?.ConnectionName, right?.Etlconnection?.ConnectionName);
            diff.AddLine("Staging Connection", left?.StageConnection?.ConnectionName, right?.StageConnection?.ConnectionName);
            diff.AddLine("Target Connection", left?.TargetConnection?.ConnectionName, right?.TargetConnection?.ConnectionName);
            diff.AddLine("Enabled", left?.EnabledIndicator, right?.EnabledIndicator);
            diff.AddLine("Deleted", left?.DeletedIndicator, right?.DeletedIndicator);
            diff.AddLine("Order ID", left?.TaskOrderId, right?.TaskOrderId);

            foreach (var taskProperty in TaskProperty)
            {
                var otherTaskProperty = right?.TaskProperty?.Where(x => x.TaskPropertyType.TaskPropertyTypeName == taskProperty.TaskPropertyType.TaskPropertyTypeName).FirstOrDefault();
                if (otherTaskProperty == null)
                {
                    diff.AddDeletion(taskProperty.TaskPropertyType.TaskPropertyTypeName);
                }
                else
                {
                    diff.AddLine(taskProperty.TaskPropertyType.TaskPropertyTypeName, taskProperty.TaskPropertyValue, otherTaskProperty.TaskPropertyValue);
                }
            }
            foreach (var taskProperty in right?.TaskProperty == null ? new List<TaskProperty>() : right.TaskProperty)
            {
                var ourTaskProperty = left?.TaskProperty.Where(x => x.TaskPropertyType.TaskPropertyTypeName == taskProperty.TaskPropertyType.TaskPropertyTypeName).FirstOrDefault();
                if (ourTaskProperty == null)
                {
                    diff.AddCreation(taskProperty.TaskPropertyType.TaskPropertyTypeName, taskProperty.TaskPropertyValue);
                }
            }

            diff.Nest("Task Passthrough Mappings", () =>
            {
                foreach (var mapping in TaskPropertyPassthroughMappingTask == null ? new List<TaskPropertyPassthroughMapping>() : TaskPropertyPassthroughMappingTask)
                {
                    var otherMapping = right?.TaskPropertyPassthroughMappingTask.Where(x => x.TaskPassthrough.TaskName == mapping.TaskPassthrough.TaskName).FirstOrDefault();
                    if (otherMapping == null)
                    {
                        diff.AddDeletion(mapping.TaskPassthrough.TaskName);
                    }
                }
                foreach (var mapping in right?.TaskPropertyPassthroughMappingTask == null ? new List<TaskPropertyPassthroughMapping>() : right.TaskPropertyPassthroughMappingTask)
                {
                    var ourMapping = TaskPropertyPassthroughMappingTask.Where(x => x.TaskPassthrough.TaskName == mapping.TaskPassthrough.TaskName).FirstOrDefault();
                    if (ourMapping == null)
                    {
                        diff.AddCreation("new mapped task", mapping.TaskPassthrough.TaskName);
                    }
                }
            });

            // For every mapping on one side, is there an exact match on the right? Then no change.
            var oneIsNull = (left == null && right != null) || (right == null && left != null);
            var differencesInLeft = oneIsNull || !left.FileColumnMapping.All(x => right.FileColumnMapping.Any(y => y.DeletedIndicator == x.DeletedIndicator && x.SourceColumnName == y.SourceColumnName && x.TargetColumnName == y.TargetColumnName && x.EnabledIndicator == y.EnabledIndicator && x.FileInterimDataType.FileInterimDataTypeName == y.FileInterimDataType.FileInterimDataTypeName));
            var differencesInRight = oneIsNull || !right.FileColumnMapping.All(x => left.FileColumnMapping.Any(y => y.DeletedIndicator == x.DeletedIndicator && x.SourceColumnName == y.SourceColumnName && x.TargetColumnName == y.TargetColumnName && x.EnabledIndicator == y.EnabledIndicator && x.FileInterimDataType.FileInterimDataTypeName == y.FileInterimDataType.FileInterimDataTypeName));
            if (differencesInLeft || differencesInRight)
            {
                diff.AddRaw("File column mappings will update. Can't preview changes.");
            }
        }

        public void Pull(Task otherTask, ADS_ConfigContext context)
        {
            TaskDescription = otherTask.TaskDescription;
            EnabledIndicator = otherTask.EnabledIndicator;
            DeletedIndicator = otherTask.DeletedIndicator;
            TaskOrderId = otherTask.TaskOrderId;

            var newTaskType = context.TaskType.Where(x => x.TaskTypeName == otherTask.TaskType.TaskTypeName).FirstOrDefault();
            if (newTaskType == null)
            {
                throw new Exception($"Can't pull. No task type by the name of {otherTask.TaskType.TaskTypeName}");
            }
            TaskType = newTaskType;
            TaskTypeId = newTaskType.TaskTypeId;

            var newSourceConnection = context.Connection.Where(x => x.ConnectionName == otherTask.SourceConnection.ConnectionName).FirstOrDefault();
            if (newSourceConnection == null)
            {
                throw new Exception($"Can't pull. No connection by the name of {otherTask.SourceConnection.ConnectionName}");
            }
            SourceConnection = newSourceConnection;
            SourceConnectionId = newSourceConnection.ConnectionId;

            if (otherTask.Etlconnection == null)
            {
                Etlconnection = null;
                EtlconnectionId = null;
            } else
            {
                var newEtlConnection = context.Connection.Where(x => x.ConnectionName == otherTask.Etlconnection.ConnectionName).FirstOrDefault();
                if (newEtlConnection == null)
                {
                    throw new Exception($"Can't pull. No connection by the name of {otherTask.Etlconnection.ConnectionName}");
                }
                Etlconnection = newEtlConnection;
                EtlconnectionId = newEtlConnection.ConnectionId;
            }

            if (otherTask.StageConnection == null)
            {
                StageConnection = null;
                StageConnectionId = null;
            }
            else
            {
                var newStageConnection = context.Connection.Where(x => x.ConnectionName == otherTask.StageConnection.ConnectionName).FirstOrDefault();
                if (newStageConnection == null)
                {
                    throw new Exception($"Can't pull. No connection by the name of {otherTask.StageConnection.ConnectionName}");
                }
                StageConnection = newStageConnection;
                StageConnectionId = newStageConnection.ConnectionId;
            }

            if (otherTask.TargetConnection == null)
            {
                TargetConnection = null;
                TargetConnectionId = null;
            }
            else
            {
                var newTargetConnection = context.Connection.Where(x => x.ConnectionName == otherTask.TargetConnection.ConnectionName).FirstOrDefault();
                if (newTargetConnection == null)
                {
                    throw new Exception($"Can't pull. No connection by the name of {otherTask.TargetConnection.ConnectionName}");
                }
                TargetConnection = newTargetConnection;
                TargetConnectionId = newTargetConnection.ConnectionId;
            }

            foreach (var taskProperty in otherTask.TaskProperty)
            {
                var ourMatchingProperty = this.TaskProperty.Where(x => x.TaskPropertyType.TaskPropertyTypeName == taskProperty.TaskPropertyType.TaskPropertyTypeName).FirstOrDefault();
                if (ourMatchingProperty != null)
                {
                    ourMatchingProperty.Pull(taskProperty, context);
                }
                else
                {
                    var newProperty = Models.TaskProperty.PullNew(taskProperty, this, context);
                    TaskProperty.Add(newProperty);
                }
            }

            // We can't correlate between these entities
            // so we have to clear the whole list out and repopulate
            foreach (var mapping in FileColumnMapping)
            {
                context.Remove(mapping);
            }
            foreach(var mapping in otherTask.FileColumnMapping)
            {
                var newMapping = Models.FileColumnMapping.PullNew(mapping, this, context);
                FileColumnMapping.Add(newMapping);
                context.Add(newMapping);
            }
        }

        public void PullPassthroughMappings(Task otherTask, ADS_ConfigContext context)
        {
            foreach (var mapping in TaskPropertyPassthroughMappingTask)
            {
                context.Remove(mapping);
            }
            foreach (var mapping in otherTask.TaskPropertyPassthroughMappingTask)
            {
                var newMapping = Models.TaskPropertyPassthroughMapping.PullNew(mapping, this, context);
                TaskPropertyPassthroughMappingTask.Add(newMapping);
                context.Add(newMapping);
            }
        }

        public static Task PullNew(Task otherTask, System system, ADS_ConfigContext context)
        {
            var newTask = new Task();
            newTask.Pull(otherTask, context);
            newTask.System = system;
            newTask.SystemId = system.SystemId;
            newTask.TaskName = otherTask.TaskName;

            context.Add(newTask);
            return newTask;
        }
    }
}
