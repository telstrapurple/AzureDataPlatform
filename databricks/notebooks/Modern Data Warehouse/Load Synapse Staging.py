# Databricks notebook source
# MAGIC %run "./Util/Config"

# COMMAND ----------

# Set Spark synapse storage account Config
synapseStorageAccountDataLake = dbutils.secrets.get(scope = "datalakeconfig", key = "synapseStorageAccountDataLake")
synapseStorageAccountContainer = dbutils.secrets.get(scope = "datalakeconfig", key = "synapseStorageAccountContainer")

spark.conf.set("fs.azure.account.auth.type." + synapseStorageAccountDataLake + ".dfs.core.windows.net", "OAuth")
spark.conf.set("fs.azure.account.oauth.provider.type." + synapseStorageAccountDataLake + ".dfs.core.windows.net", "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider")
spark.conf.set("fs.azure.account.oauth2.client.id." + synapseStorageAccountDataLake + ".dfs.core.windows.net", databricksApplicationID)
spark.conf.set("fs.azure.account.oauth2.client.secret." + synapseStorageAccountDataLake + ".dfs.core.windows.net", databricksApplicationKey)
spark.conf.set("fs.azure.account.oauth2.client.endpoint." + synapseStorageAccountDataLake + ".dfs.core.windows.net", "https://login.microsoftonline.com/"+ azureTenantID +"/oauth2/token")

# COMMAND ----------

def get_dir_content(ls_path):
  dir_paths = dbutils.fs.ls(ls_path)
  subdir_paths = [get_dir_content(p.path) for p in dir_paths if p.isDir() and p.path != ls_path]
  flat_subdir_paths = [p for subdir in subdir_paths for p in subdir]
  return list(map(lambda p: p.path, dir_paths)) + flat_subdir_paths
    
def load_staging_recursive(config):
  paths = get_dir_content(f"abfss://datalakestore@{spark.conf.get('storageAccountDataLake')}.dfs.core.windows.net/{config['path']}")
  filepaths = []
  for file in paths: 
    if ".parquet" in file: 
      filepaths.append(file.rsplit('/', 1)[0])
  for path in filepaths: 
    # read from silver area of the lake 
    df = spark.read.format(config["file_format"]).load(path)
    # get table name 
    tableName = ""
    splitted = path.split("/")
    if int(config["folder_depth"]) > 1:
      for i in reversed(range(1, int(config["folder_depth"])+1)): 
        if i != 1: 
          tableName += f'{splitted[-i].replace("/", "")}_'
        else: 
          tableName += f'{splitted[-i].replace("/", "")}'
    else:
      tableName = splitted[-i].replace("/", "")
    
    # write to sql dw
    synapseUserName = spark.conf.get("synapseUserName")
    synapsePassword = spark.conf.get("synapsePassword")
    synapseHostName = spark.conf.get("synapseHostName")
    synapseSQLPoolName = spark.conf.get("synapseSQLPoolName")
    url = f"jdbc:sqlserver://{synapseHostName};database={synapseSQLPoolName}"
    
    try: 
      df.write \
        .format("com.databricks.spark.sqldw") \
        .option("url", url) \
        .option("maxStrLength",4000) \
        .option("useAzureMSI", "true") \
        .option("user", synapseUserName) \
        .option("password", synapsePassword) \
        .option("dbTable", f"{config['schema']}.{tableName}") \
        .option("tempDir", f"abfss://{synapseStorageAccountContainer}@{synapseStorageAccountDataLake}.dfs.core.windows.net/tempDir") \
        .mode("overwrite") \
        .save()
      print(f"Successfully loaded for {config['schema']}.{tableName}")
    except Exception as e:
      print(f"Failed to load for {config['schema']}.{tableName}. Error: {e}")


# COMMAND ----------

def load_staging(config):
  if config["load_type"] == "recursive": 
    load_staging_recursive(config)
 

# COMMAND ----------

import json
# connect to datalake 

dbutils.widgets.text("ScriptConfig", '{"path": "Silver/WideWorldImportersOLTP/", "file_format": "parquet", "folder_depth": 2, "load_type": "recursive", "schema": "stg"}',"")
rawConfig = getArgument("ScriptConfig")
unicodeConfig = rawConfig.encode('unicode_escape')
config = json.loads(unicodeConfig)

load_staging(config)