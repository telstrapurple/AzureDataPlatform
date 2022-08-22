using System.Linq;
using System;

// ReSharper disable once CheckNamespace - must match other 'side' of the partial class
namespace ADPConfigurator.Domain.Models
{
    public partial class SystemProperty
    {
        public void Pull(SystemProperty otherProperty, ADS_ConfigContext context)
        {
            SystemPropertyValue = otherProperty.SystemPropertyValue;
            DeletedIndicator = otherProperty.DeletedIndicator;
        }

        public static SystemProperty PullNew(SystemProperty otherProperty, System system, ADS_ConfigContext context)
        {
            var systemPropertyType = context.SystemPropertyType.Where(x => x.SystemPropertyTypeName == otherProperty.SystemPropertyType.SystemPropertyTypeName).FirstOrDefault();
            if (systemPropertyType == null)
            {
                throw new Exception($"Can't create system property. No system property type exists by the name of {otherProperty.SystemPropertyType.SystemPropertyTypeName}");
            }
            
            var newSystemProperty =  new SystemProperty
            {
                SystemPropertyTypeId = systemPropertyType.SystemPropertyTypeId,
                SystemPropertyType = systemPropertyType,
                SystemPropertyValue = otherProperty.SystemPropertyValue,
                DeletedIndicator = otherProperty.DeletedIndicator,
                SystemId = system.SystemId,
                System = system,
            };
            context.Add(newSystemProperty);
            return newSystemProperty;
        }

        public void Diff(EntityDiff diff, SystemProperty right)
        {
            var left = this;
            diff.AddLine("Value", left.SystemPropertyValue, right.SystemPropertyValue);
            diff.AddLine("Deleted", left.DeletedIndicator, right.DeletedIndicator);
        }
    }
}
