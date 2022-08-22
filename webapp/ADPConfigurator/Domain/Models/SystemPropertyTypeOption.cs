using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class SystemPropertyTypeOption
    {
        public int SystemPropertyTypeOptionId { get; set; }
        public int SystemPropertyTypeId { get; set; }
        public string SystemPropertyTypeOptionName { get; set; }
        public string SystemPropertyTypeOptionDescription { get; set; }
        public bool? EnabledIndicator { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }

        public virtual SystemPropertyType SystemPropertyType { get; set; }
    }
}
