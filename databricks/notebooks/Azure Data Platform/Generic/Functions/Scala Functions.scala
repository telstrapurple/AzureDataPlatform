// Databricks notebook source
// MAGIC %md
// MAGIC ### Generic Scala Functions used by Generic File Load Notebooks

// COMMAND ----------

// DBTITLE 1,Import all the required libraries
import com.microsoft.azure.sqldb.spark.config.Config
import com.microsoft.azure.sqldb.spark.connect._
import com.microsoft.azure.sqldb.spark.query._
import org.apache.spark.sql.SaveMode
import com.databricks.spark.sqldw.DefaultSource

// COMMAND ----------

// DBTITLE 1,Function to bulk load a SQL table from a Databricks table using the Spark driver
def bulkCopyDBTableToSQLDB(sourceTable: String, targetDatabaseName: String, targetTable: String, writeMode: String, batchSize: String){

  val sqlUserName = spark.conf.get("sqlUserName")
  val sqlPassword = spark.conf.get("sqlPassword")
  val sqlHostName = spark.conf.get("sqlHostName")
  val sqlDatabase = targetDatabaseName
  
  if(writeMode.toUpperCase == "OVERWRITE"){
   
    //Overwrite the existing table for the bulk load
    
    val tableOverwrite = spark.sql("SELECT * FROM " + sourceTable + " WHERE 1 = 0")

    val config  = Config(Map(
      "url"                 -> sqlHostName,
      "databaseName"        -> sqlDatabase,
      "dbTable"             -> targetTable,
      "user"                -> sqlUserName,
      "password"            -> sqlPassword
    ))

    tableOverwrite.write.mode(SaveMode.Overwrite).sqlDB(config)
  }

  //Bulk copy the data
  
  val bulkCopy = spark.table(sourceTable)
  
  //Repartion to create parallel threads
  bulkCopy.repartition(4)

  val bulkCopyConfig  = Config(Map(
    "url"                 -> sqlHostName,
    "databaseName"        -> sqlDatabase,
    "dbTable"             -> targetTable,
    "user"                -> sqlUserName,
    "password"            -> sqlPassword,
    "bulkCopyBatchSize"   -> batchSize,
    "bulkCopyTableLock"   -> "true",
    "bulkCopyTimeout"     -> "0"
  ))

  bulkCopy.bulkCopyToSqlDB(bulkCopyConfig)
}

// COMMAND ----------

// DBTITLE 1,Function to bulk load a SQL table from a Databricks table using the Spark driver. Use the provided connection details
def bulkCopyDBTableToSQLDBCustomConnection(sourceTable: String, targetDatabaseName: String, targetTable: String, writeMode: String, batchSize: String, sqlHostName: String, sqlUserName: String, sqlPassword: String){
  
  if(writeMode.toUpperCase == "OVERWRITE"){
   
    //Overwrite the existing table for the bulk load
    
    val tableOverwrite = spark.sql("SELECT * FROM " + sourceTable + " WHERE 1 = 0")

    val config  = Config(Map(
      "url"                 -> sqlHostName,
      "databaseName"        -> targetDatabaseName,
      "dbTable"             -> targetTable,
      "user"                -> sqlUserName,
      "password"            -> sqlPassword
    ))

    tableOverwrite.write.mode(SaveMode.Overwrite).sqlDB(config)
  }

  //Bulk copy the data
  
  val bulkCopy = spark.table(sourceTable)
  
  //Repartion to create parallel threads
  bulkCopy.repartition(4)

  val bulkCopyConfig  = Config(Map(
    "url"                 -> sqlHostName,
    "databaseName"        -> targetDatabaseName,
    "dbTable"             -> targetTable,
    "user"                -> sqlUserName,
    "password"            -> sqlPassword,
    "bulkCopyBatchSize"   -> batchSize,
    "bulkCopyTableLock"   -> "true",
    "bulkCopyTimeout"     -> "0"
  ))

  bulkCopy.bulkCopyToSqlDB(bulkCopyConfig)
}

// COMMAND ----------

// DBTITLE 1,Function to bulk load a SQL DW table from a Databricks table using Azure SQL Data Warehouse connector for Azure Databricks
def bulkCopyDBTableToSQLDW(sourceTable: String, targetDatabaseName: String, targetTable: String, writeMode: String){

  val dwServer = spark.conf.get("sqlHostName")
  val dwUser = spark.conf.get("sqlUserName")
  val dwPass = spark.conf.get("sqlPassword")
  val dwDatabase = targetDatabaseName
  val dwUrl = "jdbc:sqlserver://"+ dwServer +":1433;database=" + dwDatabase
  val dwtableName = targetTable.replace("[","").replace("]","")
  val storageAcc = dbutils.secrets.get(scope = "datalakeconfig", key = "storageAccountDataLake")
  
  val tempDir = "abfss://datalakestore@" +  storageAcc  + ".dfs.core.windows.net/Temp"

  
  //Poly copy the data
  
  val polyCopy = spark.table(sourceTable)
  
   polyCopy.write
    .format("com.databricks.spark.sqldw")
    .option("url",dwUrl)
    .option("dbtable", dwtableName )
    .option("user", dwUser)
    .option("password", dwPass)
    .option("useAzureMSI","True")
    .option("tempdir",tempDir)
    .mode(writeMode)
    .save()
}

// COMMAND ----------

// DBTITLE 1,Function to bulk load a SQL DW table from a Databricks table using Azure SQL Data Warehouse connector for Azure Databricks. Use the provided connection details
def bulkCopyDBTableToSQLDWCustomConnection(sourceTable: String, targetDatabaseName: String, targetTable: String, writeMode: String, sqlHostName: String, sqlUserName: String, sqlPassword: String){

  val dwServer = sqlHostName
  val dwUser = sqlUserName
  val dwPass = sqlPassword
  val dwDatabase = targetDatabaseName
  val dwUrl = "jdbc:sqlserver://"+ dwServer +":1433;database=" + dwDatabase
  val dwtableName = targetTable.replace("[","").replace("]","")
  //val storageAcc = dbutils.secrets.get(scope = "datalakeconfig", key = "dataLakeAccountName")
  val storageAcc = dbutils.secrets.get(scope = "datalakeconfig", key = "storageAccountDataLake")
  
  val tempDir = "abfss://datalakestore@" +  storageAcc  + ".dfs.core.windows.net/Temp"

  
  //Poly copy the data
  
  val polyCopy = spark.table(sourceTable)
  
   polyCopy.write
    .format("com.databricks.spark.sqldw")
    .option("url",dwUrl)
    .option("dbtable", dwtableName )
    .option("user", dwUser)
    .option("password", dwPass)
    .option("useAzureMSI","True")
    .option("tempdir",tempDir)
    .mode(writeMode)
    .save()
}

// COMMAND ----------

// DBTITLE 1,Function to execute custom SQL using the Spark driver
def executeCustomSQLNoResult(targetDatabaseName: String, sqlCommand: String){

  val sqlUserName = spark.conf.get("sqlUserName")
  val sqlPassword = spark.conf.get("sqlPassword")
  val sqlHostName = spark.conf.get("sqlHostName")
  val sqlDatabase = targetDatabaseName
  
  val query = sqlCommand

  val config = Config(Map(
    "url"                 -> sqlHostName,
    "databaseName"        -> sqlDatabase,
    "user"                -> sqlUserName,
    "password"            -> sqlPassword,
    "queryCustom"         -> query
  ))
  
  sqlContext.sqlDBQuery(config)
}

// COMMAND ----------

// DBTITLE 1,Function to execute custom SQL using the Spark driver. Use the provided connection details
def executeCustomSQLNoResultCustomConnection(targetDatabaseName: String, sqlCommand: String, sqlHostName: String, sqlUserName: String, sqlPassword: String){
  
  val query = sqlCommand

  val config = Config(Map(
    "url"                 -> sqlHostName,
    "databaseName"        -> targetDatabaseName,
    "user"                -> sqlUserName,
    "password"            -> sqlPassword,
    "queryCustom"         -> query
  ))
  
  sqlContext.sqlDBQuery(config)
}

// COMMAND ----------

// DBTITLE 1,Function to execute a query and return the result using the Spark driver
def executeCustomSQLWithResult(targetDatabaseName: String, sqlCommand: String){

  val sqlUserName = spark.conf.get("sqlUserName")
  val sqlPassword = spark.conf.get("sqlPassword")
  val sqlHostName = spark.conf.get("sqlHostName")
  val sqlDatabase = targetDatabaseName
  
  val query = sqlCommand

  val config = Config(Map(
    "url"                 -> sqlHostName,
    "databaseName"        -> sqlDatabase,
    "user"                -> sqlUserName,
    "password"            -> sqlPassword,
    "queryCustom"         -> query
  ))
  
  val dfResults = sqlContext.read.sqlDB(config)
  dfResults.createOrReplaceGlobalTempView("result_executeCustomSQL")
}