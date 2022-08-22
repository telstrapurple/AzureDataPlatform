using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;

// ReSharper disable once CheckNamespace - must match other 'side' of the partial class
namespace ADPConfigurator.Domain.Models
{
    public partial class System
    {
        public void Pull(System otherSystem, ADS_ConfigContext context)
        {
            SystemDescription = otherSystem.SystemDescription;
            EnabledIndicator = otherSystem.EnabledIndicator;
            DeletedIndicator = otherSystem.DeletedIndicator;
            foreach (var systemProperty in otherSystem.SystemProperty)
            {
                var ourMatchingProperty = this.SystemProperty.Where(x => x.SystemPropertyType.SystemPropertyTypeName == systemProperty.SystemPropertyType.SystemPropertyTypeName).FirstOrDefault();
                if (ourMatchingProperty != null)
                {
                    ourMatchingProperty.Pull(systemProperty, context);
                }
                else
                {
                    var newProperty = Models.SystemProperty.PullNew(systemProperty, this, context);
                    SystemProperty.Add(newProperty);
                }
            }

            foreach (var systemDependency in otherSystem.SystemDependencySystem)
            {
                var ourMatchingSystemDependency = this.SystemDependencySystem
                    .Where(x => x.Dependency.SystemName == systemDependency.Dependency.SystemName)
                    .FirstOrDefault();

                if (ourMatchingSystemDependency != null)
                {
                    ourMatchingSystemDependency.Pull(systemDependency, context);
                }
                else
                {
                    var newSystemDependency = SystemDependency.PullNew(systemDependency, this, context);
                    this.SystemDependencySystem.Add(newSystemDependency);
                }
            }

            foreach (var task in otherSystem.Task)
            {
                var ourMatchingTask = Task.Where(t => t.TaskName == task.TaskName).FirstOrDefault();

                if (ourMatchingTask != null)
                {
                    ourMatchingTask.Pull(task, context);
                }
                else
                {
                    var newTask = Models.Task.PullNew(task, this, context);
                    Task.Add(newTask);
                }
            }

            // Pass through mappings have to be done after everything else
            // because there may be a mapping to a brand new task that needed
            // to be created in the previous step
            foreach (var task in otherSystem.Task)
            {
                var ourMatchingTask = Task.Where(t => t.TaskName == task.TaskName).FirstOrDefault();
                ourMatchingTask.PullPassthroughMappings(task, context);
            }

            context.Entry(this).State = EntityState.Modified;
        }

        public static System PullNew(System otherSystem, ADS_ConfigContext context)
        {
            var newSystem = new System
            {
                SystemCode = otherSystem.SystemCode,
                SystemName = otherSystem.SystemName,
            };

            newSystem.Pull(otherSystem, context);

            return newSystem;
        }

        public void Diff(EntityDiff diff, System right)
        {
            var left = this;
            diff.AddLine("Description", left.SystemDescription, right.SystemDescription);
            diff.AddLine("Enabled", left.EnabledIndicator, right.EnabledIndicator);
            diff.AddLine("Deleted", left.DeletedIndicator, right.DeletedIndicator);

            foreach (var systemProperty in SystemProperty)
            {
                var otherSystemProperty = right.SystemProperty.Where(x => x.SystemPropertyType.SystemPropertyTypeName == systemProperty.SystemPropertyType.SystemPropertyTypeName).FirstOrDefault();
                if (otherSystemProperty == null)
                {
                    diff.AddDeletion(systemProperty.SystemPropertyType.SystemPropertyTypeName);
                }
                else
                {
                    diff.AddLine(systemProperty.SystemPropertyType.SystemPropertyTypeName, systemProperty.SystemPropertyValue, otherSystemProperty.SystemPropertyValue);
                }
            }
            foreach (var systemProperty in right.SystemProperty)
            {
                var ourSystemProperty = left.SystemProperty.Where(x => x.SystemPropertyType.SystemPropertyTypeName == systemProperty.SystemPropertyType.SystemPropertyTypeName).FirstOrDefault();
                if (ourSystemProperty == null)
                {
                    diff.AddCreation(systemProperty.SystemPropertyType.SystemPropertyTypeName, systemProperty.SystemPropertyValue);
                }
            }

            diff.Nest("System Dependencies", () =>
            {
                foreach (var systemDependency in SystemDependencySystem)
                {
                    var otherSystemDependencySystem = right.SystemDependencySystem.Where(x => x.Dependency.SystemName == systemDependency.Dependency.SystemName).FirstOrDefault();
                    if (otherSystemDependencySystem == null)
                    {
                        diff.AddDeletion(systemDependency.Dependency.SystemName);
                    }
                    else
                    {
                        diff.Nest(systemDependency.Dependency.SystemName, () =>
                        {
                            systemDependency.Diff(diff, otherSystemDependencySystem);
                        });
                    }
                }
                foreach (var systemDependency in right.SystemDependencySystem)
                {
                    var ourSystemDependencySystem = left.SystemDependencySystem.Where(x => x.Dependency.SystemName == systemDependency.Dependency.SystemName).FirstOrDefault();
                    if (ourSystemDependencySystem == null)
                    {
                        diff.AddCreation("Dependency", systemDependency.Dependency.SystemName);
                    }
                }
            });

            diff.Nest("Tasks", () =>
            {
                foreach (var task in Task)
                {
                    var otherTask = right.Task.Where(x => x.TaskName == task.TaskName).FirstOrDefault();
                    if (otherTask == null)
                    {
                        diff.AddDeletion(task.TaskName);
                    }
                    else
                    {
                        diff.Nest(task.TaskName, () =>
                        {
                            task.Diff(diff, otherTask);
                        });
                    }
                }
                foreach (var task in right.Task)
                {
                    var ourTask = left.Task.Where(x => x.TaskName == task.TaskName).FirstOrDefault();
                    if (ourTask == null)
                    {
                        var dummy = new Task();
                        diff.Nest($"New - {task.TaskName}", () =>
                        {
                            dummy.Diff(diff, task);
                        });
                    }
                }
            });

            //foreach (var task in otherSystem.Task)
            //{
            //    var ourMatchingTask = Task.Where(t => t.TaskName == task.TaskName).FirstOrDefault();

            //    if (ourMatchingTask != null)
            //    {
            //        ourMatchingTask.Pull(task, context);
            //    }
            //    else
            //    {
            //        var newTask = Models.Task.PullNew(task, this, context);
            //        Task.Add(newTask);
            //    }
            //}
        }

        // TODO - apirational: Implement a diff function so we can show a nicer diff visualisation when pulling

        [NotMapped]
        public bool Enabled
        {
            get
            {
                // Enabled has default value == true
                return EnabledIndicator.HasValue ? EnabledIndicator.Value : true;
            }
            set
            {
                EnabledIndicator = value;
            }
        }

        [NotMapped]
        public string TargetPathPrefix
        {
            get
            {
                return $"datalakestore/adp/Raw/{SystemCode}/";
            }
        }
    }
}
