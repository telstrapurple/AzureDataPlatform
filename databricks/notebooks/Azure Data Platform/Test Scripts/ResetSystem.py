# Databricks notebook source
# MAGIC %md
# MAGIC #### README - Important
# MAGIC This script is a wrapper around the ResetTask notebook. It retrieves all the tasks for a given system and then iteratively called the nested notebook to destroy data in the following areas: 
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
# MAGIC ADS_STAGE
# MAGIC - [(SchemaName)].[(TableName)] , WHERE specified Task matches
# MAGIC - [(SchemaName)].[(TableName)_history] , WHERE specified Task matches
# MAGIC - [tempstage].[(SchemaName)_(TableName)] , WHERE specified Task matches
# MAGIC - [tempstage].[(SchemaName)_(TableName)_cdc] , WHERE specified Task matches
# MAGIC 
# MAGIC ADS_CONFIG
# MAGIC - [DI].[DataFactoryLog]     , WHERE specified Task matches
# MAGIC - [DI].[IncrementalLoadLog] , WHERE specified Task matches
# MAGIC - [DI].[FileLoadLog]        , WHERE specified Task matches
# MAGIC - [DI].[CDCLoadLog]         , WHERE specified Task matches
# MAGIC - [DI].[TaskInstance]       , WHERE specified Task matches

# COMMAND ----------

# Only run once when the notebook is first created
# dbutils.widgets.text("adsSystemID", "", "")

# COMMAND ----------

# MAGIC %md
# MAGIC ##### 1. Populate widget
# MAGIC Widget definitions
# MAGIC - adsSystemID : You can obtain the ADS System ID by navigating to a given system via the ADS User Interface. Select "Edit" on the given system, and use the value contained in the key "id". 
# MAGIC   - Example: https://websiteName.azurewebsites.net/Systems/Edit?id=1
# MAGIC     - The ID is 1

# COMMAND ----------

# MAGIC %md 
# MAGIC ##### 2. Execute the commands below

# COMMAND ----------

# MAGIC %run "ADS Go Fast/Generic/Config"

# COMMAND ----------

# MAGIC %run "ADS Go Fast/Generic/Functions/Python Functions"

# COMMAND ----------

# MAGIC %md 
# MAGIC ##### 3. Fetch the list of tasks to delete

# COMMAND ----------

# Get the Task details
systemID = getArgument("adsSystemID")
if systemID == "":
  raise Exception("Please input a value into adsSystemID")
sqlQuery_getTasks = f"""
SELECT DISTINCT
  T.TaskID
FROM
  DI.[Task] T
  INNER JOIN DI.TaskInstance TI ON T.TaskID = TI.TaskID
WHERE
  T.SystemID = {systemID}
"""
sqlResult = executeCustomSQLQuery("ADS_Config", sqlQuery_getTasks)

# Iterate through all the tasks
for taskID in sqlResult:
  # Cal the notebook to clean out each task
  dbutils.notebook.run("ResetTask", 0, {"adsTaskID":taskID.get("TaskID")})
