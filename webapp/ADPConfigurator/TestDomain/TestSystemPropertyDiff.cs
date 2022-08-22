using NUnit.Framework;
using ADPConfigurator.Domain.Models;
using ADPConfigurator.Domain;

namespace TestDomain
{
    public class TestSystemPropertyDiff
    {
        public static SystemProperty CreateSystemProperty(string prefix = "old")
        {
            var systemPropertyType = new SystemPropertyType
            {
                SystemPropertyTypeName = $"{prefix}TypeName"
            };
            return new SystemProperty
            {
                SystemPropertyType = systemPropertyType,
                SystemPropertyValue = $"{prefix}Value",
                DeletedIndicator = false
            };
        }

        [Test]
        public void CreatesANullDiffWhenEqual()
        {
            var differ = new EntityDiff();
            var left = CreateSystemProperty();
            var right = CreateSystemProperty();

            left.Diff(differ, right);
            
            Assert.True(string.IsNullOrEmpty(differ.ToString()));
        }

        [Test]
        public void CreatesADiffDisplayingChanges()
        {
            var left = CreateSystemProperty();
            var right = CreateSystemProperty();

            right.SystemPropertyValue = "newValue";
            right.DeletedIndicator = true;

            var differ = new EntityDiff();
            left.Diff(differ, right);

            Assert.AreEqual(
@"Value: oldValue => newValue
Deleted: False => True
", differ.ToString());
        }
    }
}