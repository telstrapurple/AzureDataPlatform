using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class TaskProperty
    {
        public int TaskPropertyId { get; set; }
        public int TaskPropertyTypeId { get; set; }
        public int TaskId { get; set; }
        public string TaskPropertyValue { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }

        public virtual Task Task { get; set; }
        public virtual TaskPropertyType TaskPropertyType { get; set; }
    }
}
