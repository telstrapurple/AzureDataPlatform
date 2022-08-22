using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class TaskPropertyType
    {
        public TaskPropertyType()
        {
            TaskProperty = new HashSet<TaskProperty>();
            TaskPropertyTypeOption = new HashSet<TaskPropertyTypeOption>();
            TaskTypeTaskPropertyTypeMapping = new HashSet<TaskTypeTaskPropertyTypeMapping>();
        }

        public int TaskPropertyTypeId { get; set; }
        public string TaskPropertyTypeName { get; set; }
        public string TaskPropertyTypeDescription { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }
        public int TaskPropertyTypeValidationId { get; set; }

        public virtual TaskPropertyTypeValidation TaskPropertyTypeValidation { get; set; }
        public virtual ICollection<TaskProperty> TaskProperty { get; set; }
        public virtual ICollection<TaskPropertyTypeOption> TaskPropertyTypeOption { get; set; }
        public virtual ICollection<TaskTypeTaskPropertyTypeMapping> TaskTypeTaskPropertyTypeMapping { get; set; }
    }
}
