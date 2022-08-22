using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace ADPConfigurator.Domain.Models
{
    public partial class System
    {
        public System()
        {
            SystemDependencyDependency = new HashSet<SystemDependency>();
            SystemDependencySystem = new HashSet<SystemDependency>();
            SystemProperty = new HashSet<SystemProperty>();
            Task = new HashSet<Task>();
            UserPermission = new HashSet<UserPermission>();
        }

        public int SystemId { get; set; }
        public string SystemName { get; set; }

        //[Required]
        public Guid? LocalAdminGroup { get; set; }
        //[Required]
        public Guid? MemberGroup { get; set; }
        public Guid? ReadonlyGroup { get; set; }
        public string SystemDescription { get; set; }
        public bool? EnabledIndicator { get; set; }
        public bool DeletedIndicator { get; set; }
        public DateTimeOffset DateCreated { get; set; }
        public string CreatedBy { get; set; }
        public DateTimeOffset? DateModified { get; set; }
        public string ModifiedBy { get; set; }
        public string SystemCode { get; set; }

        public virtual ICollection<SystemDependency> SystemDependencyDependency { get; set; }
        public virtual ICollection<SystemDependency> SystemDependencySystem { get; set; }
        public virtual ICollection<SystemProperty> SystemProperty { get; set; }
        public virtual ICollection<Task> Task { get; set; }

        [Obsolete("Permissions are now administrated via AAD groups")]
        public virtual ICollection<UserPermission> UserPermission { get; set; }
    }
}
