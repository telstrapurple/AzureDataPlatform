using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class ConnectionPropertyTypeValidation
    {
        public ConnectionPropertyTypeValidation()
        {
            ConnectionPropertyType = new HashSet<ConnectionPropertyType>();
        }

        public int ConnectionPropertyTypeValidationId { get; set; }
        public string ConnectionPropertyTypeValidationName { get; set; }
        public string ConnectionPropertyTypeValidationDescription { get; set; }
        public bool? EnabledIndicator { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }

        public virtual ICollection<ConnectionPropertyType> ConnectionPropertyType { get; set; }
    }
}
