using System.Linq;
using System;

// ReSharper disable once CheckNamespace - must match other 'side' of the partial class
namespace ADPConfigurator.Domain.Models
{
    public partial class FileColumnMapping
    {
        public static FileColumnMapping PullNew(FileColumnMapping otherMapping, Task task, ADS_ConfigContext context)
        {
            var newInterimDataType = context.FileInterimDataType.Where(x => x.FileInterimDataTypeName == otherMapping.FileInterimDataType.FileInterimDataTypeName).FirstOrDefault();
            if (newInterimDataType == null)
            {
                throw new Exception($"Can't pull. No interim data type by the name of {otherMapping.FileInterimDataType.FileInterimDataTypeName}");
            }
            return new FileColumnMapping
            {
                TaskId = task.TaskId,
                Task = task,
                SourceColumnName = otherMapping.SourceColumnName,
                TargetColumnName = otherMapping.TargetColumnName,
                DataLength = otherMapping.DataLength,
                FileInterimDataType = newInterimDataType,
                FileInterimDataTypeId = newInterimDataType.FileInterimDataTypeId,
                EnabledIndicator = newInterimDataType.EnabledIndicator,
                DeletedIndicator = newInterimDataType.DeletedIndicator,
            };
        }
    }
}