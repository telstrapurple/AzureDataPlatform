using System;
using Microsoft.EntityFrameworkCore;

namespace ADPConfigurator.Domain.Models
{
    public partial class ADS_ConfigContext : DbContext
    {
        public ADS_ConfigContext(DbContextOptions<ADS_ConfigContext> options)
            : base(options)
        {
        }

        public virtual DbSet<AuthenticationType> AuthenticationType { get; set; }
        public virtual DbSet<CdcloadLog> CdcloadLog { get; set; }
        public virtual DbSet<Connection> Connection { get; set; }
        public virtual DbSet<ConnectionProperty> ConnectionProperty { get; set; }
        public virtual DbSet<ConnectionPropertyType> ConnectionPropertyType { get; set; }
        public virtual DbSet<ConnectionPropertyTypeOption> ConnectionPropertyTypeOption { get; set; }
        public virtual DbSet<ConnectionPropertyTypeValidation> ConnectionPropertyTypeValidation { get; set; }
        public virtual DbSet<ConnectionType> ConnectionType { get; set; }
        public virtual DbSet<ConnectionTypeAuthenticationTypeMapping> ConnectionTypeAuthenticationTypeMapping { get; set; }
        public virtual DbSet<ConnectionTypeConnectionPropertyTypeMapping> ConnectionTypeConnectionPropertyTypeMapping { get; set; }
        public virtual DbSet<DataFactoryLog> DataFactoryLog { get; set; }
        public virtual DbSet<DatabaseTable> DatabaseTable { get; set; }
        public virtual DbSet<DatabaseTableColumn> DatabaseTableColumn { get; set; }
        public virtual DbSet<DatabaseTableConstraint> DatabaseTableConstraint { get; set; }
        public virtual DbSet<DatabaseTableRowCount> DatabaseTableRowCount { get; set; }
        public virtual DbSet<FileColumnMapping> FileColumnMapping { get; set; }
        public virtual DbSet<FileInterimDataType> FileInterimDataType { get; set; }
        public virtual DbSet<FileLoadLog> FileLoadLog { get; set; }
        public virtual DbSet<GenericConfig> GenericConfig { get; set; }
        public virtual DbSet<IncrementalLoadLog> IncrementalLoadLog { get; set; }
        public virtual DbSet<Schedule> Schedule { get; set; }
        public virtual DbSet<ScheduleInstance> ScheduleInstance { get; set; }
        public virtual DbSet<ScheduleInterval> ScheduleInterval { get; set; }
        public virtual DbSet<System> System { get; set; }
        public virtual DbSet<SystemDependency> SystemDependency { get; set; }
        public virtual DbSet<SystemProperty> SystemProperty { get; set; }
        public virtual DbSet<SystemPropertyType> SystemPropertyType { get; set; }
        public virtual DbSet<SystemPropertyTypeOption> SystemPropertyTypeOption { get; set; }
        public virtual DbSet<SystemPropertyTypeValidation> SystemPropertyTypeValidation { get; set; }
        public virtual DbSet<Task> Task { get; set; }
        public virtual DbSet<TaskInstance> TaskInstance { get; set; }
        public virtual DbSet<TaskProperty> TaskProperty { get; set; }
        public virtual DbSet<TaskPropertyPassthroughMapping> TaskPropertyPassthroughMapping { get; set; }
        public virtual DbSet<TaskPropertyType> TaskPropertyType { get; set; }
        public virtual DbSet<TaskPropertyTypeOption> TaskPropertyTypeOption { get; set; }
        public virtual DbSet<TaskPropertyTypeValidation> TaskPropertyTypeValidation { get; set; }
        public virtual DbSet<TaskResult> TaskResult { get; set; }
        public virtual DbSet<TaskType> TaskType { get; set; }
        public virtual DbSet<TaskTypeTaskPropertyTypeMapping> TaskTypeTaskPropertyTypeMapping { get; set; }
        public virtual DbSet<User> User { get; set; }
        
        [Obsolete("Permissions are now administrated via AAD groups")]
        public virtual DbSet<UserPermission> UserPermission { get; set; }
        public virtual DbSet<VwDataFactoryLog> VwDataFactoryLog { get; set; }
        public virtual DbSet<VwDataFactoryLogSystem> VwDataFactoryLogSystem { get; set; }
        public virtual DbSet<VwTaskInstanceConfig> VwTaskInstanceConfig { get; set; }


        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<AuthenticationType>(entity =>
            {
                entity.ToTable("AuthenticationType", "DI");

                entity.Property(e => e.AuthenticationTypeId).HasColumnName("AuthenticationTypeID");

                entity.Property(e => e.AuthenticationTypeDescription).HasMaxLength(250);

                entity.Property(e => e.AuthenticationTypeName)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);
            });

            modelBuilder.Entity<CdcloadLog>(entity =>
            {
                entity.ToTable("CDCLoadLog", "DI");

                entity.Property(e => e.CdcloadLogId).HasColumnName("CDCLoadLogID");

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.DeletedIndicator).HasDefaultValueSql("((0))");

                entity.Property(e => e.LatestLsnvalue)
                    .IsRequired()
                    .HasColumnName("LatestLSNValue")
                    .HasMaxLength(10)
                    .IsFixedLength();

                entity.Property(e => e.TaskInstanceId).HasColumnName("TaskInstanceID");

                entity.HasOne(d => d.TaskInstance)
                    .WithMany(p => p.CdcloadLog)
                    .HasForeignKey(d => d.TaskInstanceId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_CDCLoadLog_TaskInstance");
            });

            modelBuilder.Entity<Connection>(entity =>
            {
                entity.ToTable("Connection", "DI");

                entity.HasIndex(e => e.ConnectionName)
                    .HasName("IDXU_DI_Connection")
                    .IsUnique();

                entity.Property(e => e.ConnectionId).HasColumnName("ConnectionID");

                entity.Property(e => e.AuthenticationTypeId).HasColumnName("AuthenticationTypeID");

                entity.Property(e => e.ConnectionDescription).HasMaxLength(250);

                entity.Property(e => e.SystemCode).HasMaxLength(100);

                entity.Property(e => e.ConnectionName)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.ConnectionTypeId).HasColumnName("ConnectionTypeID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.HasOne(d => d.AuthenticationType)
                    .WithMany(p => p.Connection)
                    .HasForeignKey(d => d.AuthenticationTypeId)
                    .HasConstraintName("FK_DI_Connection_AuthenticationType");

                entity.HasOne(d => d.ConnectionType)
                    .WithMany(p => p.Connection)
                    .HasForeignKey(d => d.ConnectionTypeId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_DI_Connection_ConnectionType");
            });

            modelBuilder.Entity<ConnectionProperty>(entity =>
            {
                entity.ToTable("ConnectionProperty", "DI");

                entity.HasIndex(e => new { e.ConnectionPropertyTypeId, e.ConnectionId, e.ConnectionPropertyValue })
                    .HasName("IDXU_DI_ConnectionProperty")
                    .IsUnique();

                entity.Property(e => e.ConnectionPropertyId).HasColumnName("ConnectionPropertyID");

                entity.Property(e => e.ConnectionId).HasColumnName("ConnectionID");

                entity.Property(e => e.ConnectionPropertyTypeId).HasColumnName("ConnectionPropertyTypeID");

                entity.Property(e => e.ConnectionPropertyValue)
                    .IsRequired()
                    .HasMaxLength(4000);

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.HasOne(d => d.Connection)
                    .WithMany(p => p.ConnectionProperty)
                    .HasForeignKey(d => d.ConnectionId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("DF_DI_ConnectionProperty_Connection");

                entity.HasOne(d => d.ConnectionPropertyType)
                    .WithMany(p => p.ConnectionProperty)
                    .HasForeignKey(d => d.ConnectionPropertyTypeId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_DI_ConnectionProperty_ConnectionPropertyType");
            });

            modelBuilder.Entity<ConnectionPropertyType>(entity =>
            {
                entity.ToTable("ConnectionPropertyType", "DI");

                entity.HasIndex(e => e.ConnectionPropertyTypeName)
                    .HasName("IDXU_DI_ConnectionPropertyType")
                    .IsUnique();

                entity.Property(e => e.ConnectionPropertyTypeId).HasColumnName("ConnectionPropertyTypeID");

                entity.Property(e => e.ConnectionPropertyTypeDescription).HasMaxLength(250);

                entity.Property(e => e.ConnectionPropertyTypeName)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.ConnectionPropertyTypeValidationId).HasColumnName("ConnectionPropertyTypeValidationID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.HasOne(d => d.ConnectionPropertyTypeValidation)
                    .WithMany(p => p.ConnectionPropertyType)
                    .HasForeignKey(d => d.ConnectionPropertyTypeValidationId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_DI_ConnectionPropertyType_ConnectionPropertyTypeValidation");
            });

            modelBuilder.Entity<ConnectionPropertyTypeOption>(entity =>
            {
                entity.ToTable("ConnectionPropertyTypeOption", "DI");

                entity.Property(e => e.ConnectionPropertyTypeOptionId).HasColumnName("ConnectionPropertyTypeOptionID");

                entity.Property(e => e.ConnectionPropertyTypeId).HasColumnName("ConnectionPropertyTypeID");

                entity.Property(e => e.ConnectionPropertyTypeOptionDescription).HasMaxLength(250);

                entity.Property(e => e.ConnectionPropertyTypeOptionName)
                    .IsRequired()
                    .HasMaxLength(250);

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.HasOne(d => d.ConnectionPropertyType)
                    .WithMany(p => p.ConnectionPropertyTypeOption)
                    .HasForeignKey(d => d.ConnectionPropertyTypeId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_DI_ConnectionPropertyTypeOption_ConnectionPropertyType");
            });

            modelBuilder.Entity<ConnectionPropertyTypeValidation>(entity =>
            {
                entity.ToTable("ConnectionPropertyTypeValidation", "DI");

                entity.Property(e => e.ConnectionPropertyTypeValidationId).HasColumnName("ConnectionPropertyTypeValidationID");

                entity.Property(e => e.ConnectionPropertyTypeValidationDescription).HasMaxLength(250);

                entity.Property(e => e.ConnectionPropertyTypeValidationName)
                    .IsRequired()
                    .HasMaxLength(250);

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);
            });

            modelBuilder.Entity<ConnectionType>(entity =>
            {
                entity.ToTable("ConnectionType", "DI");

                entity.HasIndex(e => e.ConnectionTypeName)
                    .HasName("IDXU_DI_ConnectionType")
                    .IsUnique();

                entity.Property(e => e.ConnectionTypeId).HasColumnName("ConnectionTypeID");

                entity.Property(e => e.ConnectionTypeDescription).HasMaxLength(250);

                entity.Property(e => e.ConnectionTypeName)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.CrmconnectionIndicator).HasColumnName("CRMConnectionIndicator");

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.OdbcconnectionIndicator).HasColumnName("ODBCConnectionIndicator");
            });

            modelBuilder.Entity<ConnectionTypeAuthenticationTypeMapping>(entity =>
            {
                entity.ToTable("ConnectionTypeAuthenticationTypeMapping", "DI");

                entity.Property(e => e.ConnectionTypeAuthenticationTypeMappingId).HasColumnName("ConnectionTypeAuthenticationTypeMappingID");

                entity.Property(e => e.AuthenticationTypeId).HasColumnName("AuthenticationTypeID");

                entity.Property(e => e.ConnectionTypeId).HasColumnName("ConnectionTypeID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.HasOne(d => d.AuthenticationType)
                    .WithMany(p => p.ConnectionTypeAuthenticationTypeMapping)
                    .HasForeignKey(d => d.AuthenticationTypeId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_ConnectionTypeAuthenticationTypeMapping_AuthenticationTypeID");

                entity.HasOne(d => d.ConnectionType)
                    .WithMany(p => p.ConnectionTypeAuthenticationTypeMapping)
                    .HasForeignKey(d => d.ConnectionTypeId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_ConnectionTypeAuthenticationTypeMapping_ConnectionTypeID");
            });

            modelBuilder.Entity<ConnectionTypeConnectionPropertyTypeMapping>(entity =>
            {
                entity.ToTable("ConnectionTypeConnectionPropertyTypeMapping", "DI");

                entity.Property(e => e.ConnectionTypeConnectionPropertyTypeMappingId).HasColumnName("ConnectionTypeConnectionPropertyTypeMappingID");

                entity.Property(e => e.ConnectionPropertyTypeId).HasColumnName("ConnectionPropertyTypeID");

                entity.Property(e => e.ConnectionTypeAuthenticationTypeMappingId).HasColumnName("ConnectionTypeAuthenticationTypeMappingID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.HasOne(d => d.ConnectionPropertyType)
                    .WithMany(p => p.ConnectionTypeConnectionPropertyTypeMapping)
                    .HasForeignKey(d => d.ConnectionPropertyTypeId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_ConnectionTypeConnectionPropertyTypeMapping_ConnectionPropertyTypeID");

                entity.HasOne(d => d.ConnectionTypeAuthenticationTypeMapping)
                    .WithMany(p => p.ConnectionTypeConnectionPropertyTypeMapping)
                    .HasForeignKey(d => d.ConnectionTypeAuthenticationTypeMappingId)
                    .HasConstraintName("FK_ConnectionTypeAuthenticationTypeMappingConnectionPropertyTypeMapping_ConnectionTypeAuthenticationTypeMappingID");
            });

            modelBuilder.Entity<DataFactoryLog>(entity =>
            {
                entity.ToTable("DataFactoryLog", "DI");

                entity.Property(e => e.DataFactoryLogId).HasColumnName("DataFactoryLogID");

                entity.Property(e => e.ActivityName)
                    .IsRequired()
                    .HasMaxLength(100)
                    .IsUnicode(false);

                entity.Property(e => e.DataFactoryName)
                    .IsRequired()
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.FileLoadLogId).HasColumnName("FileLoadLogID");

                entity.Property(e => e.LogType)
                    .IsRequired()
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.PipelineName)
                    .IsRequired()
                    .HasMaxLength(100)
                    .IsUnicode(false);

                entity.Property(e => e.PipelineRunId)
                    .IsRequired()
                    .HasColumnName("PipelineRunID")
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.PipelineTriggerId)
                    .HasColumnName("PipelineTriggerID")
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.PipelineTriggerName)
                    .IsRequired()
                    .HasMaxLength(100)
                    .IsUnicode(false);

                entity.Property(e => e.PipelineTriggerType)
                    .IsRequired()
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.TaskInstanceId).HasColumnName("TaskInstanceID");

                entity.HasOne(d => d.FileLoadLog)
                    .WithMany(p => p.DataFactoryLog)
                    .HasForeignKey(d => d.FileLoadLogId)
                    .HasConstraintName("FK_DataFactoryLog_FileLoadLog");

                entity.HasOne(d => d.TaskInstance)
                    .WithMany(p => p.DataFactoryLog)
                    .HasForeignKey(d => d.TaskInstanceId)
                    .HasConstraintName("FK_DataFactoryLog_TaskInstance");
            });

            modelBuilder.Entity<DatabaseTable>(entity =>
            {
                entity.HasNoKey();

                entity.ToTable("DatabaseTable", "SRC");

                entity.Property(e => e.Schema)
                    .IsRequired()
                    .HasMaxLength(50);

                entity.Property(e => e.SourceSystem)
                    .IsRequired()
                    .HasMaxLength(50);

                entity.Property(e => e.SourceType)
                    .IsRequired()
                    .HasMaxLength(50);

                entity.Property(e => e.TableName)
                    .IsRequired()
                    .HasMaxLength(50);
            });

            modelBuilder.Entity<DatabaseTableColumn>(entity =>
            {
                entity.HasKey(e => new { e.ConnectionId, e.Schema, e.TableName, e.ColumnId });

                entity.ToTable("DatabaseTableColumn", "SRC");

                entity.Property(e => e.ConnectionId).HasColumnName("ConnectionID");

                entity.Property(e => e.Schema)
                    .HasMaxLength(100)
                    .IsUnicode(false);

                entity.Property(e => e.TableName)
                    .HasMaxLength(100)
                    .IsUnicode(false);

                entity.Property(e => e.ColumnId).HasColumnName("ColumnID");

                entity.Property(e => e.ColumnName)
                    .IsRequired()
                    .HasMaxLength(100)
                    .IsUnicode(false);

                entity.Property(e => e.ComputedIndicator)
                    .HasMaxLength(1)
                    .IsUnicode(false)
                    .IsFixedLength();

                entity.Property(e => e.DataLength).HasColumnType("decimal(22, 0)");

                entity.Property(e => e.DataPrecision).HasColumnType("decimal(22, 0)");

                entity.Property(e => e.DataScale).HasColumnType("decimal(22, 0)");

                entity.Property(e => e.DataType)
                    .IsRequired()
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.Nullable)
                    .HasMaxLength(1)
                    .IsUnicode(false)
                    .IsFixedLength();

                entity.HasOne(d => d.Connection)
                    .WithMany(p => p.DatabaseTableColumn)
                    .HasForeignKey(d => d.ConnectionId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_DatabaseTableColumn_Connection");
            });

            modelBuilder.Entity<DatabaseTableConstraint>(entity =>
            {
                entity.HasKey(e => new { e.ConnectionId, e.Schema, e.TableName, e.ColumnName, e.ConstraintName, e.ConstraintType });

                entity.ToTable("DatabaseTableConstraint", "SRC");

                entity.Property(e => e.ConnectionId).HasColumnName("ConnectionID");

                entity.Property(e => e.Schema)
                    .HasMaxLength(100)
                    .IsUnicode(false);

                entity.Property(e => e.TableName)
                    .HasMaxLength(100)
                    .IsUnicode(false);

                entity.Property(e => e.ColumnName)
                    .HasMaxLength(100)
                    .IsUnicode(false);

                entity.Property(e => e.ConstraintName)
                    .HasMaxLength(100)
                    .IsUnicode(false);

                entity.Property(e => e.ConstraintType)
                    .HasMaxLength(100)
                    .IsUnicode(false);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.HasOne(d => d.Connection)
                    .WithMany(p => p.DatabaseTableConstraint)
                    .HasForeignKey(d => d.ConnectionId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_DatabaseTableConstraint_Connection");
            });

            modelBuilder.Entity<DatabaseTableRowCount>(entity =>
            {
                entity.HasKey(e => new { e.ConnectionId, e.Schema, e.TableName });

                entity.ToTable("DatabaseTableRowCount", "SRC");

                entity.Property(e => e.ConnectionId).HasColumnName("ConnectionID");

                entity.Property(e => e.Schema)
                    .HasMaxLength(100)
                    .IsUnicode(false);

                entity.Property(e => e.TableName)
                    .HasMaxLength(100)
                    .IsUnicode(false);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.HasOne(d => d.Connection)
                    .WithMany(p => p.DatabaseTableRowCount)
                    .HasForeignKey(d => d.ConnectionId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_DatabaseTableRowCount_Connection");
            });

            modelBuilder.Entity<FileColumnMapping>(entity =>
            {
                entity.ToTable("FileColumnMapping", "DI");

                entity.Property(e => e.FileColumnMappingId).HasColumnName("FileColumnMappingID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DataLength)
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.FileInterimDataTypeId).HasColumnName("FileInterimDataTypeID");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.SourceColumnName)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.TargetColumnName)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.TaskId).HasColumnName("TaskID");

                entity.HasOne(d => d.FileInterimDataType)
                    .WithMany(p => p.FileColumnMapping)
                    .HasForeignKey(d => d.FileInterimDataTypeId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_FileColumnMapping_FileInterimDataTypeID");

                entity.HasOne(d => d.Task)
                    .WithMany(p => p.FileColumnMapping)
                    .HasForeignKey(d => d.TaskId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_FileColumnMapping_TaskID");
            });

            modelBuilder.Entity<FileInterimDataType>(entity =>
            {
                entity.ToTable("FileInterimDataType", "DI");

                entity.Property(e => e.FileInterimDataTypeId).HasColumnName("FileInterimDataTypeID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.FileInterimDataTypeDescription).HasMaxLength(250);

                entity.Property(e => e.FileInterimDataTypeName)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);
            });

            modelBuilder.Entity<FileLoadLog>(entity =>
            {
                entity.ToTable("FileLoadLog", "DI");

                entity.Property(e => e.FileLoadLogId).HasColumnName("FileLoadLogID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.FileName).IsRequired();

                entity.Property(e => e.FilePath).IsRequired();

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.TaskInstanceId).HasColumnName("TaskInstanceID");

                entity.HasOne(d => d.TaskInstance)
                    .WithMany(p => p.FileLoadLog)
                    .HasForeignKey(d => d.TaskInstanceId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_DI_FileLoadLog_TaskInstance");
            });

            modelBuilder.Entity<GenericConfig>(entity =>
            {
                entity.ToTable("GenericConfig", "DI");

                entity.Property(e => e.GenericConfigId).HasColumnName("GenericConfigID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.GenericConfigDescription).HasMaxLength(250);

                entity.Property(e => e.GenericConfigName)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.GenericConfigValue).IsRequired();

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);
            });

            modelBuilder.Entity<IncrementalLoadLog>(entity =>
            {
                entity.ToTable("IncrementalLoadLog", "DI");

                entity.Property(e => e.IncrementalLoadLogId).HasColumnName("IncrementalLoadLogID");

                entity.Property(e => e.EntityName)
                    .IsRequired()
                    .HasMaxLength(500);

                entity.Property(e => e.IncrementalColumn).HasMaxLength(100);

                entity.Property(e => e.LatestValue).HasMaxLength(100);

                entity.Property(e => e.TaskInstanceId).HasColumnName("TaskInstanceID");

                entity.HasOne(d => d.TaskInstance)
                    .WithMany(p => p.IncrementalLoadLog)
                    .HasForeignKey(d => d.TaskInstanceId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_IncrementalLoadLog_TaskInstance");
            });

            modelBuilder.Entity<Schedule>(entity =>
            {
                entity.ToTable("Schedule", "DI");

                entity.HasIndex(e => e.ScheduleName)
                    .HasName("IDXU_DI_Schedule")
                    .IsUnique();

                entity.Property(e => e.ScheduleId).HasColumnName("ScheduleID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.ScheduleDescription).HasMaxLength(250);

                entity.Property(e => e.ScheduleIntervalId).HasColumnName("ScheduleIntervalID");

                entity.Property(e => e.ScheduleName)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.StartDate).HasColumnType("datetime");

                entity.HasOne(d => d.ScheduleInterval)
                    .WithMany(p => p.Schedule)
                    .HasForeignKey(d => d.ScheduleIntervalId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("DI_Schedule_ScheduleInstance");
            });

            modelBuilder.Entity<ScheduleInstance>(entity =>
            {
                entity.ToTable("ScheduleInstance", "DI");

                entity.Property(e => e.ScheduleInstanceId).HasColumnName("ScheduleInstanceID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.RunDate)
                    .HasColumnType("datetime")
                    .HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.ScheduleId).HasColumnName("ScheduleID");

                entity.HasOne(d => d.Schedule)
                    .WithMany(p => p.ScheduleInstance)
                    .HasForeignKey(d => d.ScheduleId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_DI_Schedule_ScheduleInstance");
            });

            modelBuilder.Entity<ScheduleInterval>(entity =>
            {
                entity.ToTable("ScheduleInterval", "DI");

                entity.HasIndex(e => e.ScheduleIntervalName)
                    .HasName("IDXU_DI_ScheduleInterval")
                    .IsUnique();

                entity.Property(e => e.ScheduleIntervalId).HasColumnName("ScheduleIntervalID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.ScheduleIntervalDescription).HasMaxLength(250);

                entity.Property(e => e.ScheduleIntervalName)
                    .IsRequired()
                    .HasMaxLength(100);
            });

            modelBuilder.Entity<System>(entity =>
            {
                entity.ToTable("System", "DI");

                entity.HasIndex(e => e.SystemName)
                    .HasName("IDXU_DI_System")
                    .IsUnique();

                entity.Property(e => e.SystemId).HasColumnName("SystemID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.SystemCode).HasMaxLength(100);

                entity.Property(e => e.SystemDescription).HasMaxLength(250);

                entity.Property(e => e.LocalAdminGroup).HasMaxLength(36);

                entity.Property(e => e.ReadonlyGroup).HasMaxLength(36);

                entity.Property(e => e.MemberGroup).HasMaxLength(36);

                entity.Property(e => e.SystemName)
                    .IsRequired()
                    .HasMaxLength(100);
            });

            modelBuilder.Entity<SystemDependency>(entity =>
            {
                entity.ToTable("SystemDependency", "DI");

                entity.Property(e => e.SystemDependencyId).HasColumnName("SystemDependencyID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.DependencyId).HasColumnName("DependencyID");

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.SystemId).HasColumnName("SystemID");

                entity.HasOne(d => d.Dependency)
                    .WithMany(p => p.SystemDependencyDependency)
                    .HasForeignKey(d => d.DependencyId)
                    .HasConstraintName("FK_SystemDependency_DependencyID");

                entity.HasOne(d => d.System)
                    .WithMany(p => p.SystemDependencySystem)
                    .HasForeignKey(d => d.SystemId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_SystemDependency_SystemID");
            });

            modelBuilder.Entity<SystemProperty>(entity =>
            {
                entity.ToTable("SystemProperty", "DI");

                entity.Property(e => e.SystemPropertyId).HasColumnName("SystemPropertyID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.SystemId).HasColumnName("SystemID");

                entity.Property(e => e.SystemPropertyTypeId).HasColumnName("SystemPropertyTypeID");

                entity.Property(e => e.SystemPropertyValue)
                    .IsRequired()
                    .HasMaxLength(4000);

                entity.HasOne(d => d.System)
                    .WithMany(p => p.SystemProperty)
                    .HasForeignKey(d => d.SystemId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("DF_DI_SystemProperty_System");

                entity.HasOne(d => d.SystemPropertyType)
                    .WithMany(p => p.SystemProperty)
                    .HasForeignKey(d => d.SystemPropertyTypeId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_DI_SystemProperty_SystemPropertyType");
            });

            modelBuilder.Entity<SystemPropertyType>(entity =>
            {
                entity.ToTable("SystemPropertyType", "DI");

                entity.Property(e => e.SystemPropertyTypeId).HasColumnName("SystemPropertyTypeID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.SystemPropertyTypeDescription).HasMaxLength(250);

                entity.Property(e => e.SystemPropertyTypeName)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.SystemPropertyTypeValidationId).HasColumnName("SystemPropertyTypeValidationID");

                entity.HasOne(d => d.SystemPropertyTypeValidation)
                    .WithMany(p => p.SystemPropertyType)
                    .HasForeignKey(d => d.SystemPropertyTypeValidationId)
                    .HasConstraintName("FK_DI_SystemPropertyType_SystemPropertyTypeValidation");
            });

            modelBuilder.Entity<SystemPropertyTypeOption>(entity =>
            {
                entity.ToTable("SystemPropertyTypeOption", "DI");

                entity.Property(e => e.SystemPropertyTypeOptionId).HasColumnName("SystemPropertyTypeOptionID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.SystemPropertyTypeId).HasColumnName("SystemPropertyTypeID");

                entity.Property(e => e.SystemPropertyTypeOptionDescription).HasMaxLength(250);

                entity.Property(e => e.SystemPropertyTypeOptionName)
                    .IsRequired()
                    .HasMaxLength(250);

                entity.HasOne(d => d.SystemPropertyType)
                    .WithMany(p => p.SystemPropertyTypeOption)
                    .HasForeignKey(d => d.SystemPropertyTypeId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_DI_SystemPropertyTypeOption_SystemPropertyType");
            });

            modelBuilder.Entity<SystemPropertyTypeValidation>(entity =>
            {
                entity.ToTable("SystemPropertyTypeValidation", "DI");

                entity.Property(e => e.SystemPropertyTypeValidationId).HasColumnName("SystemPropertyTypeValidationID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.SystemPropertyTypeValidationDescription).HasMaxLength(250);

                entity.Property(e => e.SystemPropertyTypeValidationName)
                    .IsRequired()
                    .HasMaxLength(250);
            });

            modelBuilder.Entity<Task>(entity =>
            {
                entity.ToTable("Task", "DI");

                entity.Property(e => e.TaskId).HasColumnName("TaskID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.EtlconnectionId).HasColumnName("ETLConnectionID");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.ScheduleId).HasColumnName("ScheduleID");

                entity.Property(e => e.SourceConnectionId).HasColumnName("SourceConnectionID");

                entity.Property(e => e.StageConnectionId).HasColumnName("StageConnectionID");

                entity.Property(e => e.SystemId).HasColumnName("SystemID");

                entity.Property(e => e.TargetConnectionId).HasColumnName("TargetConnectionID");

                entity.Property(e => e.TaskDescription).HasMaxLength(250);

                entity.Property(e => e.TaskName)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.TaskOrderId).HasColumnName("TaskOrderID");

                entity.Property(e => e.TaskTypeId).HasColumnName("TaskTypeID");

                entity.HasOne(d => d.Etlconnection)
                    .WithMany(p => p.TaskEtlconnection)
                    .HasForeignKey(d => d.EtlconnectionId)
                    .HasConstraintName("FK_Task_ETLConnectionID");

                entity.HasOne(d => d.Schedule)
                    .WithMany(p => p.Task)
                    .HasForeignKey(d => d.ScheduleId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_Task_Schedule");

                entity.HasOne(d => d.SourceConnection)
                    .WithMany(p => p.TaskSourceConnection)
                    .HasForeignKey(d => d.SourceConnectionId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_Task_SourceConnection");

                entity.HasOne(d => d.StageConnection)
                    .WithMany(p => p.TaskStageConnection)
                    .HasForeignKey(d => d.StageConnectionId)
                    .HasConstraintName("FK_Task_StageConnectionID");

                entity.HasOne(d => d.System)
                    .WithMany(p => p.Task)
                    .HasForeignKey(d => d.SystemId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_Task_System");

                entity.HasOne(d => d.TargetConnection)
                    .WithMany(p => p.TaskTargetConnection)
                    .HasForeignKey(d => d.TargetConnectionId)
                    .HasConstraintName("FK_Task_TargetConnection");

                entity.HasOne(d => d.TaskType)
                    .WithMany(p => p.Task)
                    .HasForeignKey(d => d.TaskTypeId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_Task_TaskType");
            });

            modelBuilder.Entity<TaskInstance>(entity =>
            {
                entity.ToTable("TaskInstance", "DI");

                entity.Property(e => e.TaskInstanceId).HasColumnName("TaskInstanceID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.RunDate).HasColumnType("datetime");

                entity.Property(e => e.ScheduleInstanceId).HasColumnName("ScheduleInstanceID");

                entity.Property(e => e.TaskId).HasColumnName("TaskID");

                entity.Property(e => e.TaskResultId).HasColumnName("TaskResultID");

                entity.HasOne(d => d.ScheduleInstance)
                    .WithMany(p => p.TaskInstance)
                    .HasForeignKey(d => d.ScheduleInstanceId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_DI_ScheduleInstance_TaskInstance");

                entity.HasOne(d => d.Task)
                    .WithMany(p => p.TaskInstance)
                    .HasForeignKey(d => d.TaskId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_DI_Task_TaskInstance");

                entity.HasOne(d => d.TaskResult)
                    .WithMany(p => p.TaskInstance)
                    .HasForeignKey(d => d.TaskResultId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_DI_TaskResult_TaskInstance");
            });

            modelBuilder.Entity<TaskProperty>(entity =>
            {
                entity.ToTable("TaskProperty", "DI");

                entity.HasIndex(e => new { e.TaskPropertyTypeId, e.TaskId })
                    .HasName("IDXU_DI_TaskProperty")
                    .IsUnique();

                entity.Property(e => e.TaskPropertyId).HasColumnName("TaskPropertyID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.TaskId).HasColumnName("TaskID");

                entity.Property(e => e.TaskPropertyTypeId).HasColumnName("TaskPropertyTypeID");

                entity.Property(e => e.TaskPropertyValue)
                    .IsRequired()
                    .HasMaxLength(4000);

                entity.HasOne(d => d.Task)
                    .WithMany(p => p.TaskProperty)
                    .HasForeignKey(d => d.TaskId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_DI_TaskProperty_Task");

                entity.HasOne(d => d.TaskPropertyType)
                    .WithMany(p => p.TaskProperty)
                    .HasForeignKey(d => d.TaskPropertyTypeId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_DI_TaskProperty_TaskPropertyType");
            });

            modelBuilder.Entity<TaskPropertyPassthroughMapping>(entity =>
            {
                entity.ToTable("TaskPropertyPassthroughMapping", "DI");

                entity.Property(e => e.TaskPropertyPassthroughMappingId).HasColumnName("TaskPropertyPassthroughMappingID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.TaskId).HasColumnName("TaskID");

                entity.Property(e => e.TaskPassthroughId).HasColumnName("TaskPassthroughID");

                entity.HasOne(d => d.Task)
                    .WithMany(p => p.TaskPropertyPassthroughMappingTask)
                    .HasForeignKey(d => d.TaskId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_TaskPropertyPassthroughMapping_TaskID");

                entity.HasOne(d => d.TaskPassthrough)
                    .WithMany(p => p.TaskPropertyPassthroughMappingTaskPassthrough)
                    .HasForeignKey(d => d.TaskPassthroughId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_TaskPropertyPassthroughMapping_TaskPassthroughID");
            });

            modelBuilder.Entity<TaskPropertyType>(entity =>
            {
                entity.ToTable("TaskPropertyType", "DI");

                entity.HasIndex(e => e.TaskPropertyTypeName)
                    .HasName("IDXU_DI_TaskPropertyType")
                    .IsUnique();

                entity.Property(e => e.TaskPropertyTypeId).HasColumnName("TaskPropertyTypeID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.TaskPropertyTypeDescription).HasMaxLength(250);

                entity.Property(e => e.TaskPropertyTypeName)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.TaskPropertyTypeValidationId).HasColumnName("TaskPropertyTypeValidationID");

                entity.HasOne(d => d.TaskPropertyTypeValidation)
                    .WithMany(p => p.TaskPropertyType)
                    .HasForeignKey(d => d.TaskPropertyTypeValidationId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_DI_TaskPropertyType_TaskPropertyTypeValidation");
            });

            modelBuilder.Entity<TaskPropertyTypeOption>(entity =>
            {
                entity.ToTable("TaskPropertyTypeOption", "DI");

                entity.Property(e => e.TaskPropertyTypeOptionId).HasColumnName("TaskPropertyTypeOptionID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.TaskPropertyTypeId).HasColumnName("TaskPropertyTypeID");

                entity.Property(e => e.TaskPropertyTypeOptionDescription).HasMaxLength(250);

                entity.Property(e => e.TaskPropertyTypeOptionName)
                    .IsRequired()
                    .HasMaxLength(250);

                entity.HasOne(d => d.TaskPropertyType)
                    .WithMany(p => p.TaskPropertyTypeOption)
                    .HasForeignKey(d => d.TaskPropertyTypeId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_DI_TaskPropertyTypeOption_TaskPropertyType");
            });

            modelBuilder.Entity<TaskPropertyTypeValidation>(entity =>
            {
                entity.ToTable("TaskPropertyTypeValidation", "DI");

                entity.Property(e => e.TaskPropertyTypeValidationId).HasColumnName("TaskPropertyTypeValidationID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.TaskPropertyTypeValidationDescription).HasMaxLength(250);

                entity.Property(e => e.TaskPropertyTypeValidationName)
                    .IsRequired()
                    .HasMaxLength(250);
            });

            modelBuilder.Entity<TaskResult>(entity =>
            {
                entity.ToTable("TaskResult", "DI");

                entity.HasIndex(e => e.TaskResultName)
                    .HasName("IDXU_DI_TaskResult")
                    .IsUnique();

                entity.Property(e => e.TaskResultId).HasColumnName("TaskResultID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.RetryIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.TaskResultDescription).HasMaxLength(250);

                entity.Property(e => e.TaskResultName)
                    .IsRequired()
                    .HasMaxLength(100);
            });

            modelBuilder.Entity<TaskType>(entity =>
            {
                entity.ToTable("TaskType", "DI");

                entity.HasIndex(e => e.TaskTypeName)
                    .HasName("IDXU_DI_TaskType")
                    .IsUnique();

                entity.Property(e => e.TaskTypeId).HasColumnName("TaskTypeID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DatabaseLoadIndicator).HasDefaultValueSql("((0))");

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.FileLoadIndicator).HasDefaultValueSql("((0))");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.RunType)
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.ScriptIndicator).HasDefaultValueSql("((0))");

                entity.Property(e => e.TaskTypeDescription).HasMaxLength(250);

                entity.Property(e => e.TaskTypeName)
                    .IsRequired()
                    .HasMaxLength(100);
            });

            modelBuilder.Entity<TaskTypeTaskPropertyTypeMapping>(entity =>
            {
                entity.ToTable("TaskTypeTaskPropertyTypeMapping", "DI");

                entity.Property(e => e.TaskTypeTaskPropertyTypeMappingId).HasColumnName("TaskTypeTaskPropertyTypeMappingID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.ModifiedBy).HasMaxLength(50);

                entity.Property(e => e.TaskPropertyTypeId).HasColumnName("TaskPropertyTypeID");

                entity.Property(e => e.TaskTypeId).HasColumnName("TaskTypeID");

                entity.HasOne(d => d.TaskPropertyType)
                    .WithMany(p => p.TaskTypeTaskPropertyTypeMapping)
                    .HasForeignKey(d => d.TaskPropertyTypeId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_TaskTypeTaskPropertyTypeMapping_TaskPropertyTypeID");

                entity.HasOne(d => d.TaskType)
                    .WithMany(p => p.TaskTypeTaskPropertyTypeMapping)
                    .HasForeignKey(d => d.TaskTypeId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_TaskTypeTaskPropertyTypeMapping_TaskTypeID");
            });

            modelBuilder.Entity<User>(entity =>
            {
                entity.ToTable("User", "DI");

                entity.Property(e => e.UserId)
                    .HasColumnName("UserID")
                    .HasMaxLength(36)
                    .IsFixedLength();

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.EmailAddress)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.EnabledIndicator)
                    .IsRequired()
                    .HasDefaultValueSql("((1))");

                entity.Property(e => e.UserName)
                    .IsRequired()
                    .HasMaxLength(100);
            });

            modelBuilder.Entity<UserPermission>(entity =>
            {
                entity.ToTable("UserPermission", "DI");

                entity.Property(e => e.UserPermissionId).HasColumnName("UserPermissionID");

                entity.Property(e => e.CreatedBy).HasMaxLength(50);

                entity.Property(e => e.DateCreated).HasDefaultValueSql("(sysutcdatetime())");

                entity.Property(e => e.SystemId).HasColumnName("SystemID");

                entity.Property(e => e.UserId)
                    .IsRequired()
                    .HasColumnName("UserID")
                    .HasMaxLength(36)
                    .IsFixedLength();

                entity.HasOne(d => d.System)
                    .WithMany(p => p.UserPermission)
                    .HasForeignKey(d => d.SystemId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_UserPermission_System");

                entity.HasOne(d => d.User)
                    .WithMany(p => p.UserPermission)
                    .HasForeignKey(d => d.UserId)
                    .OnDelete(DeleteBehavior.ClientSetNull)
                    .HasConstraintName("FK_UserPermission_User");
            });

            modelBuilder.Entity<VwDataFactoryLog>(entity =>
            {
                entity.HasNoKey();

                entity.ToView("vw_DataFactoryLog", "DI");

                entity.Property(e => e.ActivityName)
                    .IsRequired()
                    .HasMaxLength(100)
                    .IsUnicode(false);

                entity.Property(e => e.DataFactoryLogId).HasColumnName("DataFactoryLogID");

                entity.Property(e => e.DataFactoryName)
                    .IsRequired()
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.LogType)
                    .IsRequired()
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.PipelineName)
                    .IsRequired()
                    .HasMaxLength(100)
                    .IsUnicode(false);

                entity.Property(e => e.PipelineRunId)
                    .IsRequired()
                    .HasColumnName("PipelineRunID")
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.PipelineTriggerId)
                    .HasColumnName("PipelineTriggerID")
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.PipelineTriggerName)
                    .IsRequired()
                    .HasMaxLength(100)
                    .IsUnicode(false);

                entity.Property(e => e.PipelineTriggerType)
                    .IsRequired()
                    .HasMaxLength(50)
                    .IsUnicode(false);

                entity.Property(e => e.RuntimeInMins).HasColumnName("Runtime in Mins");

                entity.Property(e => e.Schedule).HasMaxLength(4000);

                entity.Property(e => e.ScheduleDescription).HasMaxLength(250);

                entity.Property(e => e.ScheduleIntervalDescription).HasMaxLength(250);

                entity.Property(e => e.ScheduleIntervalName)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.ScheduleName)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.SourceConnectionDescription).HasMaxLength(250);

                entity.Property(e => e.SourceConnectionName)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.SystemCode).HasMaxLength(100);

                entity.Property(e => e.SystemDescription).HasMaxLength(250);

                entity.Property(e => e.SystemId).HasColumnName("SystemID");

                entity.Property(e => e.SystemName)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.TargetConnectionDescription).HasMaxLength(250);

                entity.Property(e => e.TargetConnectionName).HasMaxLength(100);

                entity.Property(e => e.TaskDescription).HasMaxLength(250);

                entity.Property(e => e.TaskInstanceId).HasColumnName("TaskInstanceID");

                entity.Property(e => e.TaskName)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.TaskTypeDescription).HasMaxLength(250);

                entity.Property(e => e.TaskTypeName)
                    .IsRequired()
                    .HasMaxLength(100);
            });

            modelBuilder.Entity<VwDataFactoryLogSystem>(entity =>
            {
                entity.HasNoKey();

                entity.ToView("vw_DataFactoryLogSystem", "DI");

                entity.Property(e => e.Schedule).HasMaxLength(4000);

                entity.Property(e => e.ScheduleName)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.SystemCode).HasMaxLength(100);

                entity.Property(e => e.SystemId).HasColumnName("SystemID");

                entity.Property(e => e.SystemName)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.SystemStatus)
                    .HasMaxLength(9)
                    .IsUnicode(false);
            });

            modelBuilder.Entity<VwTaskInstanceConfig>(entity =>
            {
                entity.HasNoKey();

                entity.ToView("vw_TaskInstanceConfig", "DI");

                entity.Property(e => e.AuthenticationType)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.ConnectionPropertyType)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.ConnectionPropertyValue)
                    .IsRequired()
                    .HasMaxLength(4000);

                entity.Property(e => e.ConnectionStage)
                    .IsRequired()
                    .HasMaxLength(7)
                    .IsUnicode(false);

                entity.Property(e => e.ConnectionType)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.SystemPropertyType).HasMaxLength(100);

                entity.Property(e => e.SystemPropertyValue).HasMaxLength(4000);

                entity.Property(e => e.TaskInstanceId).HasColumnName("TaskInstanceID");

                entity.Property(e => e.TaskPropertyType)
                    .IsRequired()
                    .HasMaxLength(100);

                entity.Property(e => e.TaskPropertyValue)
                    .IsRequired()
                    .HasMaxLength(4000);

                entity.Property(e => e.TaskType)
                    .IsRequired()
                    .HasMaxLength(100);
            });

            OnModelCreatingPartial(modelBuilder);
        }

        partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
    }
}
