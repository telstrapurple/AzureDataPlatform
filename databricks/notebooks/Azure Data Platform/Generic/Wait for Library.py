# Databricks notebook source
# MAGIC %md
# MAGIC This is a Python file that will be called upon to check if libraries are installed. It will attempt to check if specified libraries are installed and after 3 attempts, it will raise an exception. 

# COMMAND ----------

# MAGIC %run "./Functions/Python Functions"

# COMMAND ----------

import time 
# Get status 
try: 
  status = getClusterLibraryStatus("maven", {"coordinates": "com.microsoft.azure:spark-mssql-connector:1.0.1"}, "australiaeast",dbutils.secrets.get(scope = "datalakeconfig", key = "databricksToken"), False ) 
except: 
  status = "ENDPOINT_THROTTLED"
attempt = 1 
while status != "INSTALLED": 
  # Sleep for 5 mins
  print("Waiting for 5 mins for library to be installed")
  time.sleep(300)
  # Get status again 
  try:
    status = getClusterLibraryStatus("maven", {"coordinates": "com.microsoft.azure:spark-mssql-connector:1.0.1"}, "australiaeast",dbutils.secrets.get(scope = "datalakeconfig", key = "databricksToken"), False )
  except:
    status = "ENDPOINT_THROTTLED"
  attempt = attempt + 1 
  if attempt >= 3: 
    raise Exception("Failed to install com.microsoft.azure:spark-mssql-connector:1.0.1")
    break