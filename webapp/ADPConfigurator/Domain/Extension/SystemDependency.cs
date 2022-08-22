using System.Linq;
using System;

// ReSharper disable once CheckNamespace - must match other 'side' of the partial class
namespace ADPConfigurator.Domain.Models
{
    public partial class SystemDependency
    {
        public void Pull(SystemDependency otherDependency, ADS_ConfigContext context)
        {
            EnabledIndicator = otherDependency.EnabledIndicator;
            DeletedIndicator = otherDependency.DeletedIndicator;
        }

        public static SystemDependency PullNew(SystemDependency otherDependency, System system, ADS_ConfigContext context)
        {
            var dependentSystem = context.System.Where(x => x.SystemName == otherDependency.Dependency.SystemName).FirstOrDefault();
            if (dependentSystem == null)
            {
                throw new Exception($"Can't create system dependency. No system exists by the name of {otherDependency.Dependency.SystemName}");
            }
            var newDependentSystem = new SystemDependency
            {
                SystemId = system.SystemId,
                DependencyId = dependentSystem.SystemId,
                EnabledIndicator = otherDependency.EnabledIndicator,
                DeletedIndicator = otherDependency.DeletedIndicator,
                Dependency = dependentSystem,
                System = system
            };
            context.Add(newDependentSystem);
            return newDependentSystem;
        }

        public void Diff(EntityDiff diff, SystemDependency right)
        {
            var left = this;
            diff.AddLine("Enabled", left.EnabledIndicator, right.EnabledIndicator);
            diff.AddLine("Deleted", left.DeletedIndicator, right.DeletedIndicator);
        }
    }
}
