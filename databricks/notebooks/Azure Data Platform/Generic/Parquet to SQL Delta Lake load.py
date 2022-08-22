# Databricks notebook source
# dbutils.widgets.removeAll()

# COMMAND ----------

# MAGIC %md
# MAGIC #### Define the widgets

# COMMAND ----------

# Widgets for debugging 
dbutils.widgets.text("previousTargetFilePath", "","")
dbutils.widgets.text("targetFilePath", "datalakestore/Raw/e01/DimAccount1_Test/2020/07/16/16/40/","")
dbutils.widgets.text("targetTempTable", "[tempstage].[e01_DimAccount1]","")
dbutils.widgets.text("loadType", "Full","")
dbutils.widgets.text("targetDatabase", "ADP_Stage","")
dbutils.widgets.text("uniqueConstraintIndicator", "Y","")
dbutils.widgets.text("taskType", "Azure SQL to SQL","")
dbutils.widgets.text("targetTable", "[e01].[DimAccount1]","")
# Delta Lake Widgets
dbutils.widgets.text("targetDeltaFilePath", "datalakestore/Delta/e01/DimAccount1_Test/","")
dbutils.widgets.text("uniqueConstraintColumns", "AccountKey","")
dbutils.widgets.text("useDeltaLakeIndicator", "Y","")
dbutils.widgets.text("deltaLakeRetentionDays", "1","")
dbutils.widgets.text("allowSchemaDrift", "Y","")
dbutils.widgets.text("fileLoadConfig", "","")
dbutils.widgets.text("fileLoadType", "", "")
# dbutils.widgets.text("sourceConfig","","")
dbutils.widgets.text("taskInstanceID", "798", "")
# dbutils.widgets.text("taskSchema", "","")
dbutils.widgets.text("whereClause", "", "")
dbutils.widgets.text("latestLSNValue", "", "")

# COMMAND ----------

# MAGIC %md
# MAGIC #### Check if the required libraries are installed

# COMMAND ----------

# MAGIC %run "./Wait for Library"

# COMMAND ----------

# MAGIC %md
# MAGIC #### Set up the Spark config

# COMMAND ----------

# MAGIC %run "./Config"

# COMMAND ----------

# MAGIC %md
# MAGIC #### Import the generic Python functions

# COMMAND ----------

# MAGIC %run "./Functions/Python Functions"

# COMMAND ----------

# MAGIC %md
# MAGIC #### Get the arguments

# COMMAND ----------

targetDatabase = getArgument("targetDatabase")
targetTempTable = getArgument("targetTempTable") 

# Current target file path
targetContainerFilePath = getArgument("targetFilePath")
if targetContainerFilePath == "":
  print("No current target file path")
else: 
  try:
    targetContainer = targetContainerFilePath.split("/", 1)[0]
    targetFilePath = targetContainerFilePath.split("/", 1)[1]
    targetStorageAccountURIPath = "abfss://" + targetContainer + "@" + spark.conf.get("storageAccountDataLake") + ".dfs.core.windows.net/" + targetFilePath
    print(targetStorageAccountURIPath)
  except: 
    # Raise exception
    raise Exception("It appears that the user has not specified a target container or file path.")

# Previous target file path
previousTargetContainerFilePath = getArgument("previousTargetFilePath")
if previousTargetContainerFilePath == "":
  print("No previous target file path")
else: 
  try:
    previousTargetContainer = previousTargetContainerFilePath.split("/", 1)[0]
    previousTargetFilePath = previousTargetContainerFilePath.split("/", 1)[1]
    previousTargetStorageAccountURIPath = "abfss://" + previousTargetContainer + "@" + spark.conf.get("storageAccountDataLake") + ".dfs.core.windows.net/" + previousTargetFilePath
    print(previousTargetStorageAccountURIPath)
  except: 
    # Raise exception
    raise Exception("It appears that ADS has not detected a previous container or file path.")

# Target delta lake file path 
targetDeltaContainerFilePath = getArgument("targetDeltaFilePath")
if targetDeltaContainerFilePath == "":
  print("No target delta lake file path")
else: 
  try:
    targetDeltaContainer = targetDeltaContainerFilePath.split("/", 1)[0]
    targetDeltaFilePath = targetDeltaContainerFilePath.split("/", 1)[1]
    targetDeltaStorageAccountURIPath = "abfss://" + targetDeltaContainer + "@" + spark.conf.get("storageAccountDataLake") + ".dfs.core.windows.net/" + targetDeltaFilePath
    print(targetDeltaStorageAccountURIPath)
  except: 
    # Raise exception
    raise Exception("It appears that the user has not specified a delta container or file path.")
    
loadType = getArgument("loadType")
taskInstanceID = getArgument("taskInstanceID")
try:
  fileLoadType = getArgument("fileLoadType")
  sourceConfig = json.loads(getArgument("sourceConfig"))
  fileLoadConfig = json.loads(getArgument("fileLoadConfig"))
except:
  # Write warning 
  print("Could not retrieve fileLoadType, sourceConfig, taskConfig and fileLoadConfig. If this is not a file load, then ignore this message.")

# Get Task Config 
taskConfig = json.loads(getArgument("taskConfig"))
try:
  # get target file name
  for config in taskConfig:
    if config.get("ConnectionStage") == "Target":
      targetFileName = config.get("TargetFileName") 
      historyTable = config.get("HistoryTable")
      dataLakeStagingCreate = config.get("DataLakeStagingCreate")
      dataLakeStagingPartitions = int(config.get("DataLakeStagingPartitions")) # convert string to int 
      targetStagingContainerFilePath = config.get("TargetStagingFilePath")
      targetStagingContainer = targetStagingContainerFilePath.split("/", 1)[0]
      targetStagingFilePath = targetStagingContainerFilePath.split("/", 1)[1]
      targetStagingStorageAccountURIPath = "abfss://" + targetStagingContainer + "@" + spark.conf.get("storageAccountDataLake") + ".dfs.core.windows.net/" + targetStagingFilePath
      print(f"Staging URI: {targetStagingStorageAccountURIPath}")
except:
  print("Could not retrieve Target File Name or History Table or dataLakeStagingPartitions or dataLakeStagingPartitions or targetStagingContainerFilePath")

# get CDC config
useSQLCDC = "False"
latestLSNValue = getArgument("latestLSNValue")
try:
  for config in taskConfig: 
    if config.get("ConnectionStage") == "Source":
      useSQLCDC = config.get("UseSQLCDC")
    if config.get("ConnectionStage") == "Target":
      targetCDCContainerFilePath = config.get("TargetCDCFilePath")
  if targetCDCContainerFilePath == "":
    print("No CDC target file path")
  else: 
    targetCDCContainer = targetCDCContainerFilePath.split("/", 1)[0]
    targetCDCFilePath = targetCDCContainerFilePath.split("/", 1)[1]
    targetCDCStorageAccountURIPath = "abfss://" + targetCDCContainer + "@" + spark.conf.get("storageAccountDataLake") + ".dfs.core.windows.net/" + targetCDCFilePath
    print(targetCDCStorageAccountURIPath)
  targetTempCDCTable = f'{targetTempTable.split(".")[0]}.{targetTempTable.split(".")[1].replace("]","_cdc]")}'
except:
  print("Could not retrieve variables for CDC. If this is not a CDC load, then ignore this warning.")

try:
  taskSchema = json.loads(getArgument("taskSchema"))
except:
  # Write warning 
  taskSchema = {}
  print("Could not retrieve taskSchema. If this is not a load to SQL DB or Synapse, then ignore this message.")
  
uniqueConstraintIndicator = getArgument("uniqueConstraintIndicator")
taskType = getArgument("taskType")
whereClause = getArgument("whereClause")

# Delta Lake arguments
targetTable = getArgument("targetTable").replace(".", "_").replace("[", "").replace("]", "")
uniqueConstraintColumns = getArgument("uniqueConstraintColumns")
useDeltaLakeIndicator = getArgument("useDeltaLakeIndicator")
deltaLakeRetentionDays = getArgument("deltaLakeRetentionDays")
allowSchemaDrift = getArgument("allowSchemaDrift")

fileFormat = "parquet"
tempTableName = targetTempTable.replace(".", "_").replace("[", "").replace("]", "").replace("$", "").replace("(", "").replace(")", "").replace("@", "")

# COMMAND ----------

# MAGIC %md
# MAGIC #### Execute the load logic

# COMMAND ----------

from pyspark.sql import functions as F

# If sequential file load
if "file" in taskType.lower() and fileLoadType == "SequentialFileLoad":
  for file in fileLoadConfig:
    # get file load variables
    print(f'file load log id: {file.get("FileLoadLogID")}')
    print(f'task instance id : {taskInstanceID}')
    print(f'file load order by: {sourceConfig[0].get("FileLoadOrderBy")}')
    sqlCommand_previousTargetFilePathSqlCommand = "EXEC [DI].[usp_FileLoadLog_LastSuccessful_Get] " + str(taskInstanceID) + ", '" + sourceConfig[0].get("FileLoadOrderBy") + "', "  + str(file.get("FileLoadLogID"))
    if executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameConfig"), sqlCommand_previousTargetFilePathSqlCommand)[0].get("TargetFilePathName") != "":
      fileLoad_previousTargetContainerFilePath = executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameConfig"), sqlCommand_previousTargetFilePathSqlCommand)[0].get("TargetFilePathName")
      try:
        fileLoad_previousTargetContainer = fileLoad_previousTargetContainerFilePath.split("/", 1)[0]
        fileLoad_previousTargetFilePath = fileLoad_previousTargetContainerFilePath.split("/", 1)[1]
        fileLoad_previousStorageAccountURIPath = "abfss://" + fileLoad_previousTargetContainer + "@" + spark.conf.get("storageAccountDataLake") + ".dfs.core.windows.net/" + fileLoad_previousTargetFilePath
        print("Previous File: " + fileLoad_previousStorageAccountURIPath)
      except: 
        raise Exception("It appears that the user has not specified a container or file path for the previous file path: " + fileLoad_previousTargetFilePath + ".")
    else:
      fileLoad_previousTargetContainerFilePath = ""
      print("No previous target file path")
    
    # Get target file path
    fileLoad_targetFileName = targetFileName.split(".")[0] + "_" + str(file.get("FilePath").replace("/","_")) + "_" + str(file.get("FileName").split(".")[0]) + ".parquet"
    fileLoad_targetContainerFilePathName = targetContainerFilePath + fileLoad_targetFileName
    try: 
      fileLoad_targetContainer = fileLoad_targetContainerFilePathName.split("/", 1)[0]
      fileLoad_targetFilePathName = fileLoad_targetContainerFilePathName.split("/", 1)[1]
      fileLoad_targetStorageAccountURIPath = "abfss://" + fileLoad_targetContainer + "@" + spark.conf.get("storageAccountDataLake") + ".dfs.core.windows.net/" + fileLoad_targetFilePathName
      print("Target File: " + fileLoad_targetStorageAccountURIPath)
    except:
      raise Exception("It appears that the user has not specified a container or file path for the target file path: " + fileLoad_targetFilePathName + ".")
    
    # Full load with key
    if loadType == "Full" and uniqueConstraintIndicator == "Y": 
      # First load
      if fileLoad_previousTargetContainerFilePath == "":  
        dfCurrent = generateFirstLoad(fileLoad_targetStorageAccountURIPath, fileFormat, targetTempTable, tempTableName, historyTable, taskInstanceID, taskType, taskSchema)
      
      # Subsequent load  
      else: 
        dfCurrent = generateSubsequentFullLoad(fileLoad_targetStorageAccountURIPath, fileLoad_previousStorageAccountURIPath, fileFormat, fileFormat, targetTempTable, tempTableName, historyTable, taskInstanceID, taskType, taskSchema)
    
    # Incremental load with key 
    elif loadType == "Incremental" and uniqueConstraintIndicator == "Y":
      # get where clause 
      sqlWhereClauseCommand = f"""
      EXEC [DI].[usp_SQLWhereClause_Get] {taskInstanceID}  
      """
      whereClause = executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameConfig"), sqlWhereClauseCommand)[0].get("WhereClause")
      incrementalColumnName = whereClause.split("[")[1].split("]")[0]
      print(f"whereClause: {whereClause}")
      
      # First load 
      if fileLoad_previousTargetContainerFilePath == "": 
        dfCurrent = generateFirstLoad(fileLoad_targetStorageAccountURIPath, fileFormat, targetTempTable, tempTableName, historyTable, taskInstanceID, taskType, taskSchema)
      
      # Subsequent load 
      else: 
        dfCurrent = generateSubsequentIncrementalLoad(fileLoad_targetStorageAccountURIPath, targetDeltaStorageAccountURIPath, fileFormat, "delta", targetTempTable, tempTableName, historyTable, taskInstanceID, whereClause, taskType, taskSchema)
      
      taskID = executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameConfig"), f"SELECT TOP 1 TaskID FROM DI.TaskInstance WHERE TaskInstanceID = {taskInstanceID}")[0].get("TaskID")
      maxIncrementalValue = dfCurrent.agg(F.max(incrementalColumnName)).collect()[0][0]
      if maxIncrementalValue == None: 
        maxIncrementalValue = whereClause.split("'")[1]
      print(f"maxIncrementalValue: {maxIncrementalValue}")
      
      sqlIncrementalLoadLogUpdate = f"""
      EXEC [DI].[usp_IncrementalLoadLog_Update] {taskID}, {taskInstanceID}, '{incrementalColumnName}', '{maxIncrementalValue}', 1, 'File'  
      """
      print(f"sqlIncrementalLoadLogUpdate: {sqlIncrementalLoadLogUpdate}")
      result = executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameConfig"), sqlIncrementalLoadLogUpdate)
      print(result)
    
    # Load without key 
    else:
      dfCurrent = generateFullLoadNoKey(fileLoad_targetStorageAccountURIPath, fileFormat, targetTempTable, tempTableName, historyTable, taskInstanceID, taskType, taskSchema)
    
    # perform SQL load - Scala notebook
    dbutils.notebook.run("LoadSQL", 0, {"targetDatabase":targetDatabase, "targetTempTable": targetTempTable, "tempTableName": tempTableName, "taskType":taskType})
    if "to SQL" in taskType:
      sqlCommand_StagingTable_Load = "EXEC [ETL].[usp_StagingTable_Load] '" + json.dumps(taskConfig) + "', '" + json.dumps(taskSchema) + "'"
      result = executeCustomSQLQuery(targetDatabase, sqlCommand_StagingTable_Load)
      print(f"execute merge: {result}")
      print("Merge executed")
    # perform delta lake load - Python function
    print("Delta: " + targetDeltaStorageAccountURIPath)
    result = deltaLakeLoad(useDeltaLakeIndicator, targetTable, targetDeltaStorageAccountURIPath, deltaLakeRetentionDays, uniqueConstraintIndicator, uniqueConstraintColumns, tempTableName, dfCurrent)
    if result != True:
      raise Exception(result)
    # create data lake staging dataset if required 
    if dataLakeStagingCreate == "True":
      writeStagingDataLake(targetDeltaStorageAccountURIPath, targetStagingStorageAccountURIPath, targetStagingContainerFilePath, dataLakeStagingPartitions)
    # mark file as successfully loaded
    sqlCommand_FileLoadLog_Update = "[DI].[usp_FileLoadLog_Update] " + str(file.get("FileLoadLogID")) + ", '" + targetContainerFilePath + "', '" + fileLoad_targetFileName + "' , " + "1" 
    result = executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameConfig"), sqlCommand_FileLoadLog_Update)
    
# If CDC load
elif useSQLCDC == "True":
  if latestLSNValue == "": # first load 
    # write datalakepath to tempstage # contains full load - all tempstage records will be merged to stage table. 
    dfCurrent = generateFirstCDCLoad(targetStorageAccountURIPath, fileFormat, targetTempTable, tempTableName, taskInstanceID)
    # Load to SQL - Scala Notebook
    dbutils.notebook.run("LoadSQL", 0, {"targetDatabase":targetDatabase, "targetTempTable": targetTempTable, "tempTableName": tempTableName, "taskType":taskType})
    # perform delta lake load - Python function
    result = deltaLakeLoad(useDeltaLakeIndicator, targetTable, targetDeltaStorageAccountURIPath,deltaLakeRetentionDays,uniqueConstraintIndicator,uniqueConstraintColumns,tempTableName,dfCurrent)
    if result != True:
      raise Exception(result)
    # create data lake staging dataset if required 
    if dataLakeStagingCreate == "True":
      writeStagingDataLake(targetDeltaStorageAccountURIPath, targetStagingStorageAccountURIPath, targetStagingContainerFilePath, dataLakeStagingPartitions)
      
    # if history table
    if historyTable:
      # union datalakepath_df with datalakepath_cdc_df 
      dfHistory = generateFirstCDCHistoryLoad(targetStorageAccountURIPath, fileFormat, targetCDCStorageAccountURIPath, fileFormat, targetTempCDCTable, tempTableName, taskInstanceID)
      # write history to data lake
      writeHistoryTableToDataLake(dfHistory, targetStorageAccountURIPath, taskInstanceID)
      # write history to tempstage_cdc
      dbutils.notebook.run("LoadSQL", 0, {"targetDatabase":targetDatabase, "targetTempTable": targetTempCDCTable, "tempTableName": tempTableName, "taskType":taskType})
    
    # update Latest LSN Value
    if not historyTable:
      dfHistory = spark.read.format(fileFormat).load(targetCDCStorageAccountURIPath)
    maxLSNValue = dfHistory.agg({"__$start_lsn": "max"}).collect()[0][0] # max
    if maxLSNValue is not None:
      sqlCommand_insertLSN = f"EXEC [DI].[usp_CDCLoadLog_Insert] {taskInstanceID}, 0x{maxLSNValue.hex()}"
      sqlResult = executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameConfig"), sqlCommand_insertLSN) 
    else:
      print(f"No changes were captured at source.")
    
  else: # subsequent load 
    # obtain net cdc changes dataframe and append ETL_Operations at the end  
    dfUnion = generateSubsequentCDCLoad(targetStorageAccountURIPath, fileFormat, targetTempTable, tempTableName, taskInstanceID, False)
    # Load to SQL - Scala Notebook
    dbutils.notebook.run("LoadSQL", 0, {"targetDatabase":targetDatabase, "targetTempTable": targetTempTable, "tempTableName": tempTableName, "taskType":taskType})
    # perform delta lake load - Python function
    result = deltaLakeLoad(useDeltaLakeIndicator, targetTable, targetDeltaStorageAccountURIPath,deltaLakeRetentionDays,uniqueConstraintIndicator,uniqueConstraintColumns,tempTableName,dfUnion)
    if result != True:
      raise Exception(result)
    # create data lake staging dataset if required 
    if dataLakeStagingCreate == "True":
      writeStagingDataLake(targetDeltaStorageAccountURIPath, targetStagingStorageAccountURIPath, targetStagingContainerFilePath, dataLakeStagingPartitions)
        
    if historyTable:
      # union datalakepath_df with datalakepath_cdc_df 
      dfHistory = generateSubsequentCDCLoad(targetCDCStorageAccountURIPath, fileFormat, targetTempCDCTable, tempTableName, taskInstanceID, True)
      # write history to data lake
      writeHistoryTableToDataLake(dfHistory, targetStorageAccountURIPath, taskInstanceID)
      # write history to tempstage_cdc
      dbutils.notebook.run("LoadSQL", 0, {"targetDatabase":targetDatabase, "targetTempTable": targetTempCDCTable, "tempTableName": tempTableName, "taskType":taskType})
    
    # update Latest LSN Value
    if not historyTable:
      dfHistory = spark.read.format(fileFormat).load(targetCDCStorageAccountURIPath)
    maxLSNValue = dfHistory.agg({"__$start_lsn": "max"}).collect()[0][0] # max
    if maxLSNValue is not None:
      sqlCommand_insertLSN = f"EXEC [DI].[usp_CDCLoadLog_Insert] {taskInstanceID}, 0x{maxLSNValue.hex()}"
      sqlResult = executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameConfig"), sqlCommand_insertLSN) 
    else:
      print(f"No changes were captured at source.")
    
# If database load or parallel file load
else:
  # Full Load with key
  if loadType == "Full" and uniqueConstraintIndicator == "Y":  
    # First load 
    if previousTargetContainerFilePath == "": 
      dfCurrent = generateFirstLoad(targetStorageAccountURIPath, fileFormat, targetTempTable, tempTableName, historyTable, taskInstanceID, taskType, taskSchema)
    # Subsequent load
    else: 
      dfCurrent = generateSubsequentFullLoad(targetStorageAccountURIPath, previousTargetStorageAccountURIPath, fileFormat, fileFormat, targetTempTable, tempTableName, historyTable, taskInstanceID, taskType, taskSchema)
  # Incremental load with key
  elif loadType == "Incremental" and uniqueConstraintIndicator == "Y": 
    # First load 
    if previousTargetContainerFilePath == "":  
      dfCurrent = generateFirstLoad(targetStorageAccountURIPath, fileFormat, targetTempTable, tempTableName, historyTable, taskInstanceID, taskType, taskSchema)
    # Subsequent load
    else: 
      dfCurrent = generateSubsequentIncrementalLoad(targetStorageAccountURIPath, targetDeltaStorageAccountURIPath, fileFormat, "delta", targetTempTable, tempTableName, historyTable, taskInstanceID, whereClause, taskType, taskSchema)
  # Load without a key
  else:  
    dfCurrent = generateFullLoadNoKey(targetStorageAccountURIPath, fileFormat, targetTempTable, tempTableName, historyTable, taskInstanceID, taskType, taskSchema)
  
  # Load to SQL - Scala Notebook
  dbutils.notebook.run("LoadSQL", 0, {"targetDatabase":targetDatabase, "targetTempTable": targetTempTable, "tempTableName": tempTableName, "taskType":taskType})
  # perform delta lake load - Python function
  result = deltaLakeLoad(useDeltaLakeIndicator, targetTable, targetDeltaStorageAccountURIPath,deltaLakeRetentionDays,uniqueConstraintIndicator,uniqueConstraintColumns,tempTableName,dfCurrent)
  if result != True:
    raise Exception(result)
  # create data lake staging dataset if required 
  if dataLakeStagingCreate == "True":
    writeStagingDataLake(targetDeltaStorageAccountURIPath, targetStagingStorageAccountURIPath, targetStagingContainerFilePath, dataLakeStagingPartitions)
  
# completed run 
dbutils.notebook.exit("")
