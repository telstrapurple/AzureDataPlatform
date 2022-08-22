using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class TaskPropertyTypeValidation
    {
        public TaskPropertyTypeValidation()
        {
            TaskPropertyType = new HashSet<TaskPropertyType>();
        }

        public int TaskPropertyTypeValidationId { get; set; }
        public string TaskPropertyTypeValidationName { get; set; }
        public string TaskPropertyTypeValidationDescription { get; set; }
        public bool? EnabledIndicator { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }

        public virtual ICollection<TaskPropertyType> TaskPropertyType { get; set; }
    }
}
