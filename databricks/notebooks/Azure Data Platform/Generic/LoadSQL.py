# Databricks notebook source
# MAGIC %md
# MAGIC #### Setup the Spark config

# COMMAND ----------

# MAGIC %run "./Config"

# COMMAND ----------

# MAGIC %md
# MAGIC #### Import the generic Python functions

# COMMAND ----------

# MAGIC %run "./Functions/Python Functions"

# COMMAND ----------

taskType = dbutils.widgets.get("taskType")
global_temp_db = spark.conf.get("spark.sql.globalTempDatabase")

if "to Lake" not in taskType:
  targetDatabase = dbutils.widgets.get("targetDatabase")
  targetTempTable = dbutils.widgets.get("targetTempTable")
  sqlHostName = ""
  sqlDatabase = ""
  sqlUserName = ""
  sqlPassword = ""
  targetSQLConnectionString = ""
  
  # Get the connection details from the target connection string secret
  try:
    targetKeyVaultSecretName = dbutils.widgets.get("targetKeyVaultSecretName")
    if targetKeyVaultSecretName != "":
      targetSQLConnectionString = dbutils.secrets.get(scope = "datalakeconfig", key = targetKeyVaultSecretName)
      # Set the Spark config based on the new connection string
      for connectionProperty in targetSQLConnectionString.split(";"):
        if "data source" in connectionProperty.lower() or "server" in connectionProperty.lower():
          sqlHostName = connectionProperty.split("=")[1]
        elif "initial catalog" in connectionProperty.lower() or "database" in connectionProperty.lower():
          targetDatabase = connectionProperty.split("=")[1]
        elif "user id" in connectionProperty.lower() or "uid" in connectionProperty.lower():
          sqlUserName = connectionProperty.split("=")[1]
        elif "password" in connectionProperty.lower() or "pwd" in connectionProperty.lower():
          sqlPassword = connectionProperty.split("=")[1]
      if(sqlHostName == "" or targetDatabase == "" or sqlUserName == "" or sqlPassword == ""):
        raise exception("The target SQL connection string is not a valid connection string or the details could not be obtained")
  except:
    print("Could not retrieve argument targetKeyVaultSecretName. Ignore if the connection does not use custom credentials")
  tempTableName = global_temp_db + "." + dbutils.widgets.get("tempTableName")
  dfSchema = spark.table(tempTableName + "_schema")
  createSQLStatement = dfSchema.collect()[0][0]

  if "to synapse" in taskType.lower():
    # Bulk copy the data to SQL DW 
    bulkCopyDBTableToSQLDW(tempTableName, targetDatabase, targetTempTable, "overwrite")
  elif "to sql" in taskType.lower():
    # Drop the table if it exists
    executeCustomSQLQuery(targetDatabase, "DROP TABLE IF EXISTS " + targetTempTable)
    #Create the new table
    executeCustomSQLQuery(targetDatabase, createSQLStatement)
    # Bulk copy the data to SQL DB
    bulkCopyDBTableToSQLDB(tempTableName, targetDatabase, targetTempTable, "append", "1000000")
  elif "to dw stage synapse" in taskType.lower():
    # Bulk copy the data to SQL DW 
    bulkCopyDBTableToSQLDWCustomConnection(tempTableName, targetDatabase, targetTempTable, "overwrite", sqlHostName, sqlUserName, sqlPassword)
  elif "to dw stage" in taskType.lower():
    # Drop the table if it exists
    executeCustomSQLQueryCustomConnection(targetDatabase, "DROP TABLE IF EXISTS " + targetTempTable, sqlHostName, sqlUserName, sqlPassword)
    # Create the new table
    executeCustomSQLQueryCustomConnection(targetDatabase, createSQLStatement, sqlHostName, sqlUserName, sqlPassword)
    # Bulk copy the data to SQL DB
    bulkCopyDBTableToSQLDBCustomConnection(tempTableName, targetDatabase, targetTempTable, "append", "1000000", sqlHostName, sqlUserName, sqlPassword)
