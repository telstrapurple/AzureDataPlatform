// Databricks notebook source
// MAGIC %md
// MAGIC #### The script below will unmount an existing mount. 
// MAGIC ##### Only unmount as needed, say if renaming the original mount

// COMMAND ----------

dbutils.fs.unmount("/mnt/datalakestore")

// COMMAND ----------

// MAGIC %md
// MAGIC #### The script below will get the Data Lake secrets from Key Vault to mount the storage in the Databricks service
// MAGIC ##### This is to set up the mount initially. They are the equivalent of a shared drive mapping

// COMMAND ----------

dbutils.secrets.get(scope = "datalakeconfig", key = "databricksAppKey")

// COMMAND ----------

val clientEndPoint = "https://login.microsoftonline.com/" + dbutils.secrets.get(scope = "datalakeconfig", key = "azureTenantID") + "/oauth2/token"
val mountSource = "abfss://datalakestore@" + dbutils.secrets.get(scope = "datalakeconfig", key = "dataLakeAccountName")  + ".dfs.core.windows.net/" 

val configs = Map(
  "fs.azure.account.auth.type" -> "OAuth",
  "fs.azure.account.oauth.provider.type" -> "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
  "fs.azure.account.oauth2.client.id" -> dbutils.secrets.get(scope = "datalakeconfig", key = "databricksAppID"),
  "fs.azure.account.oauth2.client.secret" -> dbutils.secrets.get(scope = "datalakeconfig", key = "databricksAppKey"),
  "fs.azure.account.oauth2.client.endpoint" -> clientEndPoint)

// Optionally, you can add <your-directory-name> to the source URI of your mount point.
dbutils.fs.mount(
  source = mountSource,
  mountPoint = "/mnt/datalakestore",
  extraConfigs = configs)

// COMMAND ----------

// MAGIC %md
// MAGIC #### The script below can be used to browse the contents of the mount to make sure it is working
// MAGIC ##### Will list all files available in the mount and is used to test access

// COMMAND ----------

dbutils.fs.ls("/mnt/datalakestore")