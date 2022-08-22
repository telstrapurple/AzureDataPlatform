# Databricks notebook source
# MAGIC %md
# MAGIC #### README
# MAGIC This script will perform a soft delete for: 
# MAGIC 
# MAGIC ConfigDB
# MAGIC - [DI].[CDCLoadLog]         , WHERE specified Task matches

# COMMAND ----------

# MAGIC %md
# MAGIC ##### 1. Remove widgets (if required)

# COMMAND ----------

dbutils.widgets.removeAll()

# COMMAND ----------

# MAGIC %md
# MAGIC ##### 2. Create blank widgets
# MAGIC 
# MAGIC     

# COMMAND ----------

# Create blank widgets
dbutils.widgets.text("adsTaskID", "","")

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
if taskId == "":
  raise Exception("Please input a value into adsTaskID")

# Get ConfigDB changes
sqlQuery_cdcLoadLog = f"""
UPDATE DI.CDCLoadLog 
SET DeletedIndicator = 1
FROM [DI].[CDCLoadLog] CLL INNER JOIN DI.TaskInstance TI ON CLL.TaskInstanceID = TI.TaskInstanceID
WHERE TI.TaskID = {taskId}
"""

print("[REVIEW] The following SQL Statements will be executed against ADS Config to change records from the tables below:")
print(f"- [DI].[CDCLoadLog]: {sqlQuery_cdcLoadLog}")

# COMMAND ----------

# MAGIC %md 
# MAGIC ##### 6. Execute changes and deletes, and then review the logs

# COMMAND ----------

# Changes to ADS Config tables
print("\n[LOG] Changes to ADS Config tables:")

sqlResult = executeCustomSQLQuery(spark.conf.get("sqlDatabaseNameConfig"), sqlQuery_cdcLoadLog)
if "error" in sqlResult.lower():
  print(f"- [WARNING] Failed to execute the following statement: {sqlQuery_cdcLoadLog}")
else:
  print(f"- [SUCCESS] Successful execution of: {sqlQuery_cdcLoadLog}")