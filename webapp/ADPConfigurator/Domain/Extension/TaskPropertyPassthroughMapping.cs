using System.Linq;
using System;

// ReSharper disable once CheckNamespace - must match other 'side' of the partial class
namespace ADPConfigurator.Domain.Models
{
    public partial class TaskPropertyPassthroughMapping
    {
        public static TaskPropertyPassthroughMapping PullNew(TaskPropertyPassthroughMapping otherMapping, Task task, ADS_ConfigContext context)
        {
            var mappedTask = context.Task.Where(x => x.TaskName == otherMapping.TaskPassthrough.TaskName).FirstOrDefault();
            if (mappedTask == null)
            {
                throw new Exception($"Can't pull. Tried to map property passthrough for task, but no task by the name of {otherMapping.TaskPassthrough.TaskName}");
            }

            return new TaskPropertyPassthroughMapping
            {
                TaskId = task.TaskId,
                Task = task,
                TaskPassthroughId = mappedTask.TaskId,
                TaskPassthrough = mappedTask,
                EnabledIndicator = otherMapping.EnabledIndicator,
                DeletedIndicator = otherMapping.DeletedIndicator
            };
        }
    }
}