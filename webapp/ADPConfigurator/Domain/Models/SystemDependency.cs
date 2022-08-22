using System;

namespace ADPConfigurator.Domain.Models
{
    public partial class SystemDependency
    {
        public int SystemDependencyId { get; set; }
        public int SystemId { get; set; }
        public int? DependencyId { get; set; }
        public bool? EnabledIndicator { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }

        public virtual System Dependency { get; set; }
        public virtual System System { get; set; }
    }
}
