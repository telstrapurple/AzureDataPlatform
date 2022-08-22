# Databricks notebook source
# DBTITLE 1,Delta Config
# MAGIC %scala
# MAGIC val  storageAccountDataLake = dbutils.secrets.get(scope = "datalakeconfig", key = "storageAccountDataLake")
# MAGIC spark.sparkContext.hadoopConfiguration.set( "fs.azure.account.key."+ storageAccountDataLake + ".dfs.core.windows.net", dbutils.secrets.get(scope="datalakeconfig",key="storageAccountAccesskeys")
# MAGIC )

# COMMAND ----------

# DBTITLE 1,Set Up Config
# MAGIC %run "./Config"

# COMMAND ----------

# DBTITLE 1,Add Widgets
dbutils.widgets.text("targetFilePath","datalakestore/Raw/SynapseTemp/Clarizen Data/WorkItem/2021/10/28/","")
dbutils.widgets.text("targetFileName","ClarizenDelta.parquet","")
dbutils.widgets.text("sqlQuery",'SELECT * FROM [ads_delta_lake].[clarizen_workitem]',"")

# COMMAND ----------

# DBTITLE 1,Getting Arguments
targetFilePath = getArgument("targetFilePath")
targetFileName = getArgument("targetFileName").replace(".parquet",'') 
sqlQuery = getArgument("sqlQuery") 

#Getting Datalake file Path
TargetContainer = targetFilePath.split("/", 1)[0]
TargetFilePath = targetFilePath.split("/", 1)[1]
TargetStorageAccountURIPath = "abfss://" + TargetContainer + "@" + spark.conf.get("storageAccountDataLake") + ".dfs.core.windows.net/" + TargetFilePath

target = TargetStorageAccountURIPath
#target

#Setting the SQL Query
sqlQuery = sqlQuery.replace('[','').replace(']','').replace('"','')
sqlQuery

# COMMAND ----------

# DBTITLE 1,Writing to Raw as Parquet 
df= spark.sql(sqlQuery)
df.repartition(1).write.mode("overwrite").parquet(target)

# COMMAND ----------

# DBTITLE 1,Removing Unwanted files
fileList = dbutils.fs.ls(target)
for file in fileList: 
    if file.path.endswith(".parquet"):
      print(file.path)
    else:
      print("Deleting " + file.path)
      dbutils.fs.rm(file.path)

# COMMAND ----------


