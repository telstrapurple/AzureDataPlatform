using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class SystemPropertyType
    {
        public SystemPropertyType()
        {
            SystemProperty = new HashSet<SystemProperty>();
            SystemPropertyTypeOption = new HashSet<SystemPropertyTypeOption>();
        }

        public int SystemPropertyTypeId { get; set; }
        public string SystemPropertyTypeName { get; set; }
        public string SystemPropertyTypeDescription { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }
        public int? SystemPropertyTypeValidationId { get; set; }

        public virtual SystemPropertyTypeValidation SystemPropertyTypeValidation { get; set; }
        public virtual ICollection<SystemProperty> SystemProperty { get; set; }
        public virtual ICollection<SystemPropertyTypeOption> SystemPropertyTypeOption { get; set; }
    }
}
