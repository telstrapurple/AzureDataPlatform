# Databricks notebook source
# MAGIC %md
# MAGIC #### The script below will unmount an existing mount. 
# MAGIC ##### Only unmount as needed, say if renaming the original mount

# COMMAND ----------

dbutils.fs.unmount("/mnt/datalakestore")

# COMMAND ----------

# MAGIC %md
# MAGIC #### The script below will get the Data Lake secrets from Key Vault to mount the storage in the Databricks service
# MAGIC ##### This is to set up the mount initially. They are the equivalent of a shared drive mapping

# COMMAND ----------

mountSource = "abfss://datalakestore@" + dbutils.secrets.get(scope = "datalakeconfig", key = "storageAccountDataLake")  + ".dfs.core.windows.net/" 

configs = {
  "fs.azure.account.auth.type": "CustomAccessToken",  
  "fs.azure.account.custom.token.provider.class": spark.conf.get("spark.databricks.passthrough.adls.gen2.tokenProviderClassName")
}

# Optionally, you can add <your-directory-name> to the source URI of your mount point.
dbutils.fs.mount(
  source = mountSource,
  mount_point  = "/mnt/datalakestore",
  extra_configs  = configs)

# COMMAND ----------

# MAGIC %md
# MAGIC #### The script below can be used to list the contents of the mount to make sure it is working
# MAGIC ##### Will list all files available in the mount and is used to test access

# COMMAND ----------

dbutils.fs.ls("/mnt/datalakestore/")