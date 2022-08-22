using System;
using System.Collections.Generic;

namespace ADPConfigurator.Domain.Models
{
    public partial class ConnectionPropertyType
    {
        public ConnectionPropertyType()
        {
            ConnectionProperty = new HashSet<ConnectionProperty>();
            ConnectionPropertyTypeOption = new HashSet<ConnectionPropertyTypeOption>();
            ConnectionTypeConnectionPropertyTypeMapping = new HashSet<ConnectionTypeConnectionPropertyTypeMapping>();
        }

        public int ConnectionPropertyTypeId { get; set; }
        public string ConnectionPropertyTypeName { get; set; }
        public string ConnectionPropertyTypeDescription { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }
        public int ConnectionPropertyTypeValidationId { get; set; }

        public virtual ConnectionPropertyTypeValidation ConnectionPropertyTypeValidation { get; set; }
        public virtual ICollection<ConnectionProperty> ConnectionProperty { get; set; }
        public virtual ICollection<ConnectionPropertyTypeOption> ConnectionPropertyTypeOption { get; set; }
        public virtual ICollection<ConnectionTypeConnectionPropertyTypeMapping> ConnectionTypeConnectionPropertyTypeMapping { get; set; }
    }
}
