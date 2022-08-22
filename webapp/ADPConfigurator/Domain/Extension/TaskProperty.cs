using System.Linq;
using System;

// ReSharper disable once CheckNamespace - must match other 'side' of the partial class
namespace ADPConfigurator.Domain.Models
{
    public partial class TaskProperty
    {
        public void Pull(TaskProperty otherProperty, ADS_ConfigContext context)
        {
            TaskPropertyValue = otherProperty.TaskPropertyValue;
            DeletedIndicator = otherProperty.DeletedIndicator;
        }

        public static TaskProperty PullNew(TaskProperty otherProperty, Task task, ADS_ConfigContext context)
        {
            var taskPropertyType = context.TaskPropertyType.Where(x => x.TaskPropertyTypeName == otherProperty.TaskPropertyType.TaskPropertyTypeName).FirstOrDefault();
            if (taskPropertyType == null)
            {
                throw new Exception($"Can't create task property. No task property type exists by the name of {otherProperty.TaskPropertyType.TaskPropertyTypeName}");
            }
            
            var newTaskProperty =  new TaskProperty
            {
                TaskPropertyTypeId = taskPropertyType.TaskPropertyTypeId,
                TaskPropertyType = taskPropertyType,
                TaskPropertyValue = otherProperty.TaskPropertyValue,
                DeletedIndicator = otherProperty.DeletedIndicator,
                TaskId = task.TaskId,
                Task = task,
            };
            context.Add(newTaskProperty);
            return newTaskProperty;
        }
    }
}
