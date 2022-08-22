using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class SystemPropertyTypeValidation
    {
        public SystemPropertyTypeValidation()
        {
            SystemPropertyType = new HashSet<SystemPropertyType>();
        }

        public int SystemPropertyTypeValidationId { get; set; }
        public string SystemPropertyTypeValidationName { get; set; }
        public string SystemPropertyTypeValidationDescription { get; set; }
        public bool? EnabledIndicator { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }

        public virtual ICollection<SystemPropertyType> SystemPropertyType { get; set; }
    }
}
