using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class TaskPropertyTypeOption
    {
        public int TaskPropertyTypeOptionId { get; set; }
        public int TaskPropertyTypeId { get; set; }
        public string TaskPropertyTypeOptionName { get; set; }
        public string TaskPropertyTypeOptionDescription { get; set; }
        public bool? EnabledIndicator { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }

        public virtual TaskPropertyType TaskPropertyType { get; set; }
    }
}
