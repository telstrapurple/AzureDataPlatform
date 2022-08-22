# Databricks notebook source
# MAGIC %md
# MAGIC #### Get and Set the config for the secrets
# MAGIC 
# MAGIC Obtain Storage Account secrets from Azure Key Vault (dbutils.secrets.get) and set these variables in spark config (spark.conf.set). This will provide permissions for Databricks to access Key Vault Secrets which it requires to establish connections to the Storage Account. 
# MAGIC 
# MAGIC Creating Secret Scope
# MAGIC * A Secret Scope has been created to give permissions to Databricks to get secrets from Azure Key Vault 
# MAGIC * See details on how to setup here: https://docs.azuredatabricks.net/user-guide/secrets/secret-scopes.html
# MAGIC * To view secret scopes that have already been created, you will need to set up Databricks CLI on your machine: https://docs.azuredatabricks.net/user-guide/dev-tools/databricks-cli.html#databricks-cli
# MAGIC * After you have configured Databricks CLI, run the following command to list scopes: databricks secrets list-scopes
# MAGIC 
# MAGIC Accessing Secret Scope
# MAGIC * Now that the Secret Scope has been created to Azure Key Vault, Databricks can get the secrets using dbutils.secrets.get. 
# MAGIC 
# MAGIC Spark Config Set
# MAGIC * Now that the secrets have been obtained, the secrets can be set in Spark Config such that the secrets are stored as parameters in Spark Config for the duration that the cluster is active.

# COMMAND ----------

# Get secrets / variables
synapseUserName = dbutils.secrets.get(scope = "datalakeconfig", key = "databricksSqlUsername")
synapsePassword = dbutils.secrets.get(scope = "datalakeconfig", key = "databricksSqlPassword")
synapseHostName = dbutils.secrets.get(scope = "datalakeconfig", key = "synapseFQDN")
synapseSQLPoolName = dbutils.secrets.get(scope = "datalakeconfig", key = "synapseSQLPool")
functionAppPowershellMasterKey = dbutils.secrets.get(scope = "datalakeconfig", key = "functionAppPowershellMasterKey")
functionAppBaseURL = dbutils.secrets.get(scope = "datalakeconfig", key = "functionAppBaseURL")
databricksApplicationKey = dbutils.secrets.get(scope = "datalakeconfig", key = "databricksApplicationKey")
storageAccountDataLake = dbutils.secrets.get(scope = "datalakeconfig", key = "storageAccountDataLake")
databricksApplicationID = dbutils.secrets.get(scope = "datalakeconfig", key = "databricksApplicationID")
azureTenantID = dbutils.secrets.get(scope = "datalakeconfig", key = "azureTenantID")

# Set Spark storage account Config
spark.conf.set("fs.azure.account.auth.type." + storageAccountDataLake + ".dfs.core.windows.net", "OAuth")
spark.conf.set("fs.azure.account.oauth.provider.type." + storageAccountDataLake + ".dfs.core.windows.net", "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider")
spark.conf.set("fs.azure.account.oauth2.client.id." + storageAccountDataLake + ".dfs.core.windows.net", databricksApplicationID)
spark.conf.set("fs.azure.account.oauth2.client.secret." + storageAccountDataLake + ".dfs.core.windows.net", databricksApplicationKey)
spark.conf.set("fs.azure.account.oauth2.client.endpoint." + storageAccountDataLake + ".dfs.core.windows.net", "https://login.microsoftonline.com/"+ azureTenantID +"/oauth2/token")
# Set Spark custom config
spark.conf.set("synapseUserName", synapseUserName)
spark.conf.set("synapsePassword", synapsePassword)
spark.conf.set("synapseHostName", synapseHostName)
spark.conf.set("synapseSQLPoolName", synapseSQLPoolName)
spark.conf.set("functionAppBaseURL", functionAppBaseURL)
spark.conf.set("functionAppPowershellMasterKey", functionAppPowershellMasterKey)
spark.conf.set("databricksApplicationKey", databricksApplicationKey)
spark.conf.set("storageAccountDataLake", storageAccountDataLake)
spark.conf.set("databricksApplicationID", databricksApplicationID)
spark.conf.set("azureTenantID", azureTenantID)
