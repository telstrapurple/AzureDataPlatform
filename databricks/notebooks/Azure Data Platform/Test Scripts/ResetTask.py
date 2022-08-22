# Databricks notebook source
# MAGIC %md
# MAGIC #### README - Important
# MAGIC This script will destroy data in the following areas: 
# MAGIC 
# MAGIC DATA LAKE
# MAGIC - datalakestore/Raw/[SystemName]/[TableName]     , WHERE specified Task matches
# MAGIC - datalakestore/Raw/[SystemName]/[TableName]_cdc     , WHERE specified Task matches
# MAGIC - datalakestore/Schema/[SystemName]/[TableName]  , WHERE specified Task matches
# MAGIC - datalakestore/Delta/[SystemName]/[TableName]   , WHERE specified Task matches
# MAGIC - datalakestore/History/[SystemName]/[TableName] , WHERE specified Task matches
# MAGIC - datalakestore/Staging/[SystemName]/[TableName] , WHERE specified Task matches
# MAGIC 
# MAGIC DELTA TABLE
# MAGIC - ads_delta_lake.SchemaName_TableName     , WHERE specified Task matches
# MAGIC 
# MAGIC StageDB
# MAGIC - [(SchemaName)].[(TableName)] , WHERE specified Task matches
# MAGIC - [(SchemaName)].[(TableName)_history] , WHERE specified Task matches
# MAGIC - [tempstage].[(SchemaName)_(TableName)] , WHERE specified Task matches
# MAGIC - [tempstage].[(SchemaName)_(TableName)_cdc] , WHERE specified Task matches
# MAGIC 
# MAGIC ConfigDB
# MAGIC - [DI].[DataFactoryLog]     , WHERE specified Task matches
# MAGIC - [DI].[IncrementalLoadLog] , WHERE specified Task matches
# MAGIC - [DI].[FileLoadLog]        , WHERE specified Task matches
# MAGIC - [DI].[CDCLoadLog]         , WHERE specified Task matches
# MAGIC - [DI].[TaskInstance]       , WHERE specified Task matches

# COMMAND ----------

# MAGIC %md
# MAGIC ##### 1. Remove widgets (if required)

# COMMAND ----------

#dbutils.widgets.removeAll()

# COMMAND ----------

# MAGIC %md
# MAGIC ##### 2. Create blank widgets
# MAGIC 
# MAGIC     

# COMMAND ----------

# Create blank widgets
dbutils.widgets.text("adsTaskID", "","")
dbutils.widgets.text("storageAccountName", "", "")
dbutils.widgets.text("storageAccountContainer", "", "")

# COMMAND ----------

# MAGIC %md
# MAGIC ##### 3. Populate widgets (above)
# MAGIC Widget definitions
# MAGIC - adsTaskID : You can obtain the ADS Task ID by navigating to a given Task via the ADS User Interface. Select "Edit" on the given task, and use the value contained in the key "id". 
# MAGIC   - Example: https://websiteName.azurewebsites.net/Systems/Tasks/Edit?id=1
# MAGIC     - The ID is 1

# COMMAND ----------

# MAGIC %md 
# MAGIC ##### 4. Execute the commands below

# COMMAND ----------

# MAGIC %run "Azure Data Platform/Generic/Config"

# COMMAND ----------

# MAGIC %md 
# MAGIC ##### 5. Review changes and deletes

# COMMAND ----------

import requests
import json
# execute custom sql query function 
def executeCustomSQLQuery(databaseName, sqlQuery): 
  functionAppBaseURL = spark.conf.get("functionAppBaseURL")
  if "/" != functionAppBaseURL[-1]:
    functionAppBaseURL + "/"
  functionAppURL = functionAppBaseURL + "/api/ExecuteSQLQuery"

  headers={
    'x-functions-key': spark.conf.get("functionAppPowershellMasterKey")
  }

  data = {
    'serverName' : spark.conf.get("sqlHostName"),
    'databaseName' : databaseName,
    'sqlQuery' : sqlQuery
  }

  response = requests.post(url=functionAppURL, headers=headers, json=data)
  try:
    response_json = json.loads(response.text).get("Result")
    return response_json
  except:
    return response.text

# Get the Task details
taskId = getArgument("adsTaskID")
storageAccountContainer = getArgument("storageAccountContainer")
storageAccountName = getArgument("storageAccountName")

if taskId == "":
  raise Exception("Please input a value into adsTaskID")
sqlQuery_getTaskDetails = f"""
DECLARE @TaskInstanceID AS INT; 
SET @TaskInstanceID = (SELECT MAX(TaskInstanceID) FROM DI.TaskInstance WHERE TaskID = {taskId} );
EXEC [DI].[usp_TaskInstanceConfig_Get] @TaskInstanceID
"""
sqlResult = executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameConfig"), sqlQuery_getTaskDetails)
# Get the Target connection stage 
targetStage = ""
for stage in sqlResult: 
  if stage.get("ConnectionStage") == "Target":
    targetStage = stage

# Get Data Lake changes
dataLake_delta = f'abfss://{storageAccountContainer}@{storageAccountName}.dfs.core.windows.net/{targetStage.get("TargetDeltaFilePath").replace(f"{storageAccountContainer}/","")}' 
dataLake_raw = dataLake_delta.replace("Delta", "Raw")
dataLake_cdc = f"{dataLake_raw[:-1]}_cdc/" 
dataLake_schema = dataLake_delta.replace("Delta", "Schema")
dataLake_history = dataLake_delta.replace("Delta", "History")
dataLake_staging = dataLake_delta.replace("Delta", "Staging")

print("[REVIEW] The following folders and underlying blobs in the Data Lake will be deleted:")
print(f"- {dataLake_delta}")
print(f"- {dataLake_raw}")
print(f"- {dataLake_cdc}")
print(f"- {dataLake_schema}")
print(f"- {dataLake_history}")
print(f"- {dataLake_staging}")
print("")

# Get Delta Table changes
delta_stageTable = targetStage.get("TargetTable").replace("[","").replace("]","").replace(".","_").lower()

print("[REVIEW] The following Databricks Table will be dropped from ads_delta_lake:")
print(f"- {delta_stageTable}")
print("")

# Get StageDB changes
sql_stageTable = targetStage.get("TargetTable")
sql_tempstageTable = targetStage.get("TargetTempTable")
sqlQuery_dropStageTable = f"""
DROP TABLE IF EXISTS {sql_stageTable}  
"""

schemaName = sql_stageTable.split(".")[0]
tableName = sql_stageTable.split(".")[1].replace("[","").replace("]","")
sql_stageHistoryTable = f"{schemaName}.[{tableName}_history]" 
sqlQuery_dropStageHistoryTable = f"""
DROP TABLE IF EXISTS {sql_stageHistoryTable}  
"""

sqlQuery_dropTempstageTable = f"""
DROP TABLE IF EXISTS {sql_tempstageTable}  
"""

sql_stageCDCTable = f"{schemaName}.[{tableName}_cdc]" 
sqlQuery_dropStageCDCTable = f"""
DROP TABLE IF EXISTS {sql_stageCDCTable}  
"""

print("[REVIEW] The following tables in ADS Stage will be dropped:")
print(f"- {sql_stageTable}: {sqlQuery_dropStageTable}")
print(f"- {sql_stageHistoryTable}: {sqlQuery_dropStageHistoryTable}")
print(f"- {sql_tempstageTable}: {sqlQuery_dropTempstageTable}")
print(f"- {sql_stageCDCTable}: {sqlQuery_dropStageCDCTable}")
print("")

# Get ConfigDB changes
sqlQuery_dataFactoryLog = f"""
DELETE DFL FROM [DI].[DataFactoryLog] DFL INNER JOIN DI.TaskInstance TI ON DFL.TaskInstanceID = TI.TaskInstanceID
WHERE TI.TaskID = {taskId}
"""

sqlQuery_incrementalLoadLog = f"""
DELETE ILL FROM [DI].[IncrementalLoadLog] ILL INNER JOIN DI.TaskInstance TI ON ILL.TaskInstanceID = TI.TaskInstanceID
WHERE TI.TaskID = {taskId}
"""

sqlQuery_fileLoadLog = f"""
DELETE FLL FROM [DI].[FileLoadLog] FLL INNER JOIN DI.TaskInstance TI ON FLL.TaskInstanceID = TI.TaskInstanceID
WHERE TI.TaskID = {taskId}
"""

sqlQuery_cdcLoadLog = f"""
DELETE CLL FROM [DI].[CDCLoadLog] CLL INNER JOIN DI.TaskInstance TI ON CLL.TaskInstanceID = TI.TaskInstanceID
WHERE TI.TaskID = {taskId}
"""

sqlQuery_taskInstance = f"""
DELETE TI FROM [DI].[TaskInstance] TI
WHERE TI.TaskID = {taskId}
"""

print("[REVIEW] The following SQL Statements will be executed against ADS Config to delete records from the tables below:")
print(f"- [DI].[DataFactoryLog]: {sqlQuery_dataFactoryLog}")
print(f"- [DI].[IncrementalLoadLog]: {sqlQuery_incrementalLoadLog}")
print(f"- [DI].[FileLoadLog]: {sqlQuery_fileLoadLog}")
print(f"- [DI].[CDCLoadLog]: {sqlQuery_cdcLoadLog}")
print(f"- [DI].[TaskInstance]: {sqlQuery_taskInstance}")

# COMMAND ----------

# MAGIC %md 
# MAGIC ##### 6. Execute changes and deletes, and then review the logs

# COMMAND ----------

# Delete from data lake 
print("\n[LOG] Deleting from Data Lake:")
try: 
  dbutils.fs.rm(f"{dataLake_delta}", recurse=True)
  print(f"- [SUCCESS] Delete successful for: {dataLake_delta} ")
except:
  print(f"- [WARNING] Could not delete: {dataLake_delta}. Check if path exists.")
try:
  dbutils.fs.rm(f"{dataLake_raw}", recurse=True)
  print(f"- [SUCCESS] Delete successful for: {dataLake_raw} ")
except:
  print(f"- [WARNING] Could not delete: {dataLake_raw}. Check if path exists.")
try:
  dbutils.fs.rm(f"{dataLake_cdc}", recurse=True)
  print(f"- [SUCCESS] Delete successful for: {dataLake_cdc} ")
except:
  print(f"- [WARNING] Could not delete: {dataLake_cdc}. Check if path exists.")
try:
  dbutils.fs.rm(f"{dataLake_schema}", recurse=True)
  print(f"- [SUCCESS] Delete successful for: {dataLake_schema} ")
except:
  print(f"- [WARNING] Could not delete: {dataLake_schema}. Check if path exists.")
try:
  dbutils.fs.rm(f"{dataLake_history}", recurse=True)
  print(f"- [SUCCESS] Delete successful for: {dataLake_history} ")
except:
  print(f"- [WARNING] Could not delete: {dataLake_history}. Check if path exists.")
try:
  dbutils.fs.rm(f"{dataLake_staging}", recurse=True)
  print(f"- [SUCCESS] Delete successful for: {dataLake_staging} ")
except:
  print(f"- [WARNING] Could not delete: {dataLake_staging}. Check if path exists.")

# Drop delta lake table 
print("\n[LOG] Dropping tables from Databricks ads_delta_lake:")
try:
  spark.sql(f"DROP TABLE ads_delta_lake.{delta_stageTable}")
  print(f"- [SUCCESS] The following table was dropped successfully from ads_delta_lake: ads_delta_lake.{delta_stageTable}")
except:
  print(f"- [WARNING] Could not drop ads_delta_lake.{delta_stageTable}. Check if table exists.")

# Drop ADS Stage tables
print("\n[LOG] Dropping tables from ADS Stage:")
sqlResult = executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameStage"), sqlQuery_dropStageTable)
if "error" in sqlResult.lower():
  print(f"- [WARNING] Failed to drop {sql_stageTable} using the following statement: {sqlQuery_dropStageTable}")
else:
  print(f"- [SUCCESS] Drop table was successful for: {sql_stageTable}")

sqlResult = executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameStage"), sqlQuery_dropStageHistoryTable)
if "error" in sqlResult.lower():
  print(f"- [WARNING] Failed to drop {sql_stageHistoryTable} using the following statement: {sqlQuery_dropStageHistoryTable}")
else:
  print(f"- [SUCCESS] Drop table was successful for: {sql_stageHistoryTable}")
  
sqlResult = executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameStage"), sqlQuery_dropTempstageTable)
if "error" in sqlResult.lower():
  print(f"- [WARNING] Failed to drop {sql_tempstageTable} using the following statement: {sqlQuery_dropTempstageTable}")
else:
  print(f"- [SUCCESS] Drop table was successful for: {sql_tempstageTable}")

sqlResult = executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameStage"), sqlQuery_dropStageCDCTable)
if "error" in sqlResult.lower():
  print(f"- [WARNING] Failed to drop {sql_stageCDCTable} using the following statement: {sqlQuery_dropStageCDCTable}")
else:
  print(f"- [SUCCESS] Drop table was successful for: {sql_stageCDCTable}")
  
# Delete from ADS Config tables
print("\n[LOG] Delete from ADS Config tables:")
sqlResult = executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameConfig"), sqlQuery_dataFactoryLog)
if "error" in sqlResult.lower():
  print(f"- [WARNING] Failed to execute the following statement: {sqlQuery_dataFactoryLog}")
else:
  print(f"- [SUCCESS] Successful execution of: {sqlQuery_dataFactoryLog}")
  
sqlResult = executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameConfig"), sqlQuery_incrementalLoadLog)
if "error" in sqlResult.lower():
  print(f"- [WARNING] Failed to execute the following statement: {sqlQuery_incrementalLoadLog}")
else:
  print(f"- [SUCCESS] Successful execution of: {sqlQuery_incrementalLoadLog}")

sqlResult = executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameConfig"), sqlQuery_dataFactoryLog)
if "error" in sqlResult.lower():
  print(f"- [WARNING] Failed to execute the following statement: {sqlQuery_dataFactoryLog}")
else:
  print(f"- [SUCCESS] Successful execution of: {sqlQuery_dataFactoryLog}")

sqlResult = executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameConfig"), sqlQuery_fileLoadLog)
if "error" in sqlResult.lower():
  print(f"- [WARNING] Failed to execute the following statement: {sqlQuery_fileLoadLog}")
else:
  print(f"- [SUCCESS] Successful execution of: {sqlQuery_fileLoadLog}")
  
sqlResult = executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameConfig"), sqlQuery_cdcLoadLog)
if "error" in sqlResult.lower():
  print(f"- [WARNING] Failed to execute the following statement: {sqlQuery_cdcLoadLog}")
else:
  print(f"- [SUCCESS] Successful execution of: {sqlQuery_cdcLoadLog}")

sqlResult = executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameConfig"), sqlQuery_taskInstance)
if "error" in sqlResult.lower():
  print(f"- [WARNING] Failed to execute the following statement: {sqlQuery_taskInstance}")
else:
  print(f"- [SUCCESS] Successful execution of: {sqlQuery_taskInstance}")
