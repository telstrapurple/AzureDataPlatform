using ADPConfigurator.Domain.Models;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Threading.Tasks;

namespace ADPConfigurator.Domain.Repositories
{
    public class SystemRepository
    {
        private ADS_ConfigContext _context;

        public SystemRepository(ADS_ConfigContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Gets a full copy of the system and all its related entities.
        /// Needs to be split into a series of enumerated steps because systems
        /// are quite large, and a single query includes so many joins that low-tier
        /// SQL server instances will time out on the request.
        /// </summary>
        public async Task<Models.System> GetFullyTraversedSystem(string systemName)
        {
            var fullSystem = _context.System.Where(x => x.SystemName == systemName)
                .FirstOrDefault();

            var systemProperties = _context.SystemProperty.Include("SystemPropertyType").Where(x => x.SystemId == fullSystem.SystemId).ToList();
            fullSystem.SystemProperty = systemProperties;

            var systemDependencies = await _context.SystemDependency
                .Include("Dependency").Where(x => x.SystemId == fullSystem.SystemId).ToListAsync();
            fullSystem.SystemDependencySystem = systemDependencies;

            var tasks = await _context.Task
                .Include("Etlconnection")
                .Include("Schedule")
                .Include("SourceConnection")
                .Include("TargetConnection")
                .Include("TaskType")
                .Include("FileColumnMapping")
                .Include("FileColumnMapping.FileInterimDataType")
                .Where(x => x.SystemId == fullSystem.SystemId).ToListAsync();

            foreach (var task in tasks)
            {
                var taskProperties = await _context.TaskProperty.Include("TaskPropertyType")
                    .Where(x => x.TaskId == task.TaskId)
                    .ToListAsync();

                task.TaskProperty = taskProperties;

                var mappings = await _context.TaskPropertyPassthroughMapping
                    .Include("TaskPassthrough")
                    .Where(x => x.TaskId == task.TaskId)
                    .ToListAsync();

                task.TaskPropertyPassthroughMappingTask = mappings;
            }

            fullSystem.Task = tasks;

            return fullSystem;
        }
    }
}
