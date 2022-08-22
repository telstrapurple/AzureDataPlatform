# Databricks notebook source
#dbutils.widgets.removeAll()

# COMMAND ----------

# MAGIC %md
# MAGIC #### Define the widgets

# COMMAND ----------

# Widgets for debugging 
dbutils.widgets.text("targetFilePath", "datalakestore/Raw/CRM/Category/2020/03/05","")
dbutils.widgets.text("columnName", "modifiedon","")

# COMMAND ----------

# MAGIC %md
# MAGIC #### Set up the Spark config

# COMMAND ----------

# MAGIC %run "./Config"

# COMMAND ----------

# MAGIC %md
# MAGIC #### Get the arguments

# COMMAND ----------

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

#Gets all the areguments to variables
targetFilePath = targetStorageAccountURIPath
columnName = getArgument("columnName")

# COMMAND ----------

# MAGIC %md
# MAGIC #### Import the required libraries

# COMMAND ----------

from pyspark.sql import functions as F

# COMMAND ----------

# MAGIC %md
# MAGIC #### Logic to Get the Max value for incremental load column 

# COMMAND ----------

  #Get the data  
  dfCurrent = spark.read.format("parquet").load(targetFilePath)
  #Get the Max value
  returnValue = dfCurrent.agg(F.max(columnName)).collect()[0][0]

# COMMAND ----------

# MAGIC %md
# MAGIC #### Return the Value 

# COMMAND ----------

if dfCurrent.count() > 0:
  dbutils.notebook.exit(str(returnValue))
else:
  dbutils.notebook.exit(str())
