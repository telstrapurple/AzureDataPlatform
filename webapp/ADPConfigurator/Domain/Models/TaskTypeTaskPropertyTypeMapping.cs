using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class TaskTypeTaskPropertyTypeMapping
    {
        public int TaskTypeTaskPropertyTypeMappingId { get; set; }
        public int TaskTypeId { get; set; }
        public int TaskPropertyTypeId { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }

        public virtual TaskPropertyType TaskPropertyType { get; set; }
        public virtual TaskType TaskType { get; set; }
    }
}
