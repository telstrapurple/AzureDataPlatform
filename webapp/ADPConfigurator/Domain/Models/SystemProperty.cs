using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class SystemProperty
    {
        public int SystemPropertyId { get; set; }
        public int SystemPropertyTypeId { get; set; }
        public int SystemId { get; set; }
        public string SystemPropertyValue { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }

        public virtual System System { get; set; }
        public virtual SystemPropertyType SystemPropertyType { get; set; }
    }
}
