using NUnit.Framework;
using ADPConfigurator.Domain.Models;
using ADPConfigurator.Domain;
using System.Collections.ObjectModel;
using System.Collections.Generic;
using System.Linq;

namespace TestDomain
{
    public class TestSystemDiff
    {
        private ADPConfigurator.Domain.Models.System _createSystem(string prefix = "old")
        {
            var systemProperties = new Collection<SystemProperty>();
            systemProperties.Add(TestSystemPropertyDiff.CreateSystemProperty(prefix));
            var tasks = new List<Task>
            {
                TestTaskDiff.CreateTask()
            };

            return new ADPConfigurator.Domain.Models.System
            {
                SystemName = $"{prefix} Name",
                SystemDescription = $"{prefix} Description",
                SystemCode = $"{prefix} code",
                SystemProperty = systemProperties,
                Task = tasks
            };
        }

        [Test]
        public void DifferentSystemCodeIsNotIncludedInDiff()
        {
            var diff = new EntityDiff();

            var left = _createSystem();
            var right = _createSystem();
            right.SystemCode = "4567";

            left.Diff(diff, right);

            Assert.True(string.IsNullOrEmpty(diff.ToString()));
        }

        [Test]
        public void DifferentSystemNameIsIncludedInDiff()
        {
            var diff = new EntityDiff();

            var left = _createSystem();
            var right = _createSystem();
            right.SystemDescription = "New Description";

            left.Diff(diff, right);

            Assert.AreEqual(@"Description: old Description => New Description
", diff.ToString());
        }

        [Test]
        public void CanDiffAMinimalSystem()
        {
            var minimalLeftDiff = new EntityDiff();
            var minimalRightDiff = new EntityDiff();

            var full = _createSystem();
            var minimal = new ADPConfigurator.Domain.Models.System();

            full.Diff(minimalRightDiff, minimal);
            minimal.Diff(minimalLeftDiff, full);

            var minimalLeftDiffResult = minimalLeftDiff.ToString();
            var minimalRightDiffResult = minimalRightDiff.ToString();

            Assert.AreEqual(
@"Removed: Description
Removed: oldTypeName
Tasks:
    Removed: oldName
", minimalRightDiffResult);

            Assert.AreEqual(
@"Added Description: old Description
Added oldTypeName: oldValue
Tasks:
    New - oldName:
        Added Description: oldDescription
        Added Type: oldTaskTypeName
        Added Source Connection: oldConnection
        Added ETL Connection: oldConnection
        Added Staging Connection: oldConnection
        Added Target Connection: oldConnection
        Added Enabled: True
        Added Order ID: 1
        Added oldTaskTypeName: oldValue
        File column mappings will update. Can't preview changes.
", minimalLeftDiffResult);
        }

        [Test]
        public void FindsNewTasks()
        {
            var diff = new EntityDiff();
            var left = _createSystem();
            var right = _createSystem();
            right.Task.Add(TestTaskDiff.CreateTask("two"));

            left.Diff(diff, right);

            Assert.AreEqual(
@"Tasks:
    New - twoName:
        Added Description: twoDescription
        Added Type: twoTaskTypeName
        Added Source Connection: twoConnection
        Added ETL Connection: twoConnection
        Added Staging Connection: twoConnection
        Added Target Connection: twoConnection
        Added Enabled: True
        Added Order ID: 1
        Added oldTaskTypeName: twoValue
        File column mappings will update. Can't preview changes.
", diff.ToString());
        }

        [Test]
        public void DiffsTheFullObjectTree()
        {
            var diff = new EntityDiff();
            var left = _createSystem();
            var right = _createSystem("new");
            right.Task.Add(TestTaskDiff.CreateTask("second"));
            right.Task.First().TaskPropertyPassthroughMappingTask = new List<TaskPropertyPassthroughMapping>();

            left.Diff(diff, right);

            Assert.AreEqual(
@"Description: old Description => new Description
Removed: oldTypeName
Added newTypeName: newValue
Tasks:
    New - secondName:
        Added Description: secondDescription
        Added Type: secondTaskTypeName
        Added Source Connection: secondConnection
        Added ETL Connection: secondConnection
        Added Staging Connection: secondConnection
        Added Target Connection: secondConnection
        Added Enabled: True
        Added Order ID: 1
        Added oldTaskTypeName: secondValue
        File column mappings will update. Can't preview changes.
", diff.ToString());
        }
    }
}
