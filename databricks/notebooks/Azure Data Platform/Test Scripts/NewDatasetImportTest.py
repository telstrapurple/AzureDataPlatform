# Databricks notebook source
# MAGIC %md
# MAGIC ##### 1. Remove widgets (if required)

# COMMAND ----------

dbutils.widgets.removeAll()

# COMMAND ----------

# MAGIC %md
# MAGIC ##### 2. Create blank widgets

# COMMAND ----------

# Create blank widgets
dbutils.widgets.text("rawParquetFilePath", "","") 
dbutils.widgets.text("deltaLakeFilePath", "","") 
dbutils.widgets.text("sqlTableName", "","")
dbutils.widgets.text("schemaFilePath", "","")
dbutils.widgets.text("sqlDataLineageEnabled", "","")

# COMMAND ----------

# MAGIC %md
# MAGIC ##### 3. Populate widgets (above)
# MAGIC 
# MAGIC Widget definitions
# MAGIC - rawParquetFilePath : path to the parquet files in the storage account: `/mnt/datalakestore/Raw/[SystemName]/[SchemaName]/[DatasetName]/[MostRecentDateTimeSubFolder]`
# MAGIC - deltaLakeFilePath : path to the delta files in the storage account: `/mnt/datalakestore/Delta/[SystemName]/[SchemaName]/[DatasetName]`
# MAGIC - sqlTableName : name of the SQL Table located in ADS_Stage: `[SchemaName].[TableName]`
# MAGIC - schemaFilePath : path to the schema json files in the storage account: `/mnt/datalakestore/Schema/[SystemName]/[SchemaName]/[DatasetName]/[MostRecentDateTimeSubFolder]`
# MAGIC - sqlDataLineageEnabled : `True` or `False` depending on what was configured in the Azure Data Platform UI 

# COMMAND ----------

# MAGIC %md 
# MAGIC ##### 4. Execute test script below
# MAGIC 
# MAGIC The script below performs the following (in order):
# MAGIC 1. Gets arguments from widgets
# MAGIC 2. Loads datasets 
# MAGIC 3. Performs tests on datasets
# MAGIC 
# MAGIC The following tests are performed as part of the script (in order): 
# MAGIC 1. Row Count Test : verifies that row counts match between Raw, Delta and SQL. Note that this test should be run on the FIRST load. Subsequent loads will result in Delta and SQL having more records than Raw. 
# MAGIC 2. Column Count Test : verifies that the number of columns match between Raw, Delta and SQL.
# MAGIC 3. Column Name Test : verifies that the name of the columns match between Raw, Delta and SQL.

# COMMAND ----------

### Utility functions ### 

# utility function to remove column names that are Data Lineage related 
def removeSqlDataLineageColumns(sqlColumns):
  removeList = ["ADS_DateCreated", "ADS_TaskInstanceID"] # add more ADS Data Lineage column names here that you wish to remove
  cleanList = []
  for column in sqlColumns:
    if column not in removeList:
      cleanList.append(column)
  return cleanList 

### Obtain argumnets ####

# get arguments from widgets
rawParquetFilePath = getArgument("rawParquetFilePath")
deltaLakeFilePath = getArgument("deltaLakeFilePath")
sqlTableName = getArgument("sqlTableName")
schemaFilePath = getArgument("schemaFilePath")
sqlDataLineageEnabled = eval(getArgument("sqlDataLineageEnabled"))

# obtain SQL config from key vault backed secret scope
sqlUserName = dbutils.secrets.get(scope = "datalakeconfig", key = "databricksSqlUsername")
sqlPassword = dbutils.secrets.get(scope = "datalakeconfig", key = "databricksSqlPassword")
sqlHostName = dbutils.secrets.get(scope = "datalakeconfig", key = "sqlServerFQDN")
sqlDatabase = dbutils.secrets.get(scope = "datalakeconfig", key = "sqlDatabaseNameStage")
sqlPort = 1433

### Perform loads ####

# load raw parquet
dfRaw = spark.read.format("parquet").load(rawParquetFilePath)

# load SQL
jdbcUrl = f"jdbc:sqlserver://{sqlHostName}:{sqlPort};database={sqlDatabase}" 
connectionProperties = {
  "user" : sqlUserName,
  "password" : sqlPassword,
  "driver" : "com.microsoft.sqlserver.jdbc.SQLServerDriver"
}

rowCountPushdownQuery = f"(select count(*) as rowCounts from {sqlTableName}) alias"
dfSQLRowCount = spark.read.jdbc(url=jdbcUrl, table=rowCountPushdownQuery, properties=connectionProperties)
sqlRowCount = dfSQLRowCount.collect()[0][0]
columnPushdownQuery = f"(select top 1 * from {sqlTableName}) alias"
dfSQLColumn = spark.read.jdbc(url=jdbcUrl, table=columnPushdownQuery, properties=connectionProperties)

# load delta
dfDelta = spark.read.format("delta").load(deltaLakeFilePath)

# load json 
dfJson = spark.read.format("json").load(schemaFilePath)

### Perform tests ####

# row count test 

if dfRaw.count() == sqlRowCount == dfDelta.count(): 
  print("[Test] Row Count: PASSED")
  rowCountTestPassed = True
  pass 
else: 
  print("[Test] Row Count: FAILED")
  rowCountTestPassed = False

# column count test 
sqlColumnCount = len(removeSqlDataLineageColumns(dfSQLColumn.columns))

if len(dfRaw.columns) == sqlColumnCount == len(dfDelta.columns): 
  print("[Test] Column Count: PASSED")
  columnCountTestPass = True
else: 
  print("[Test] Column Count: FAILED")
  columnCountTestPass = False

# column name comparison test
"""
Note : When comparing Parquet columns, we are using the Schema file generated. This is because the parquet file may have columns renamed in order to meet the parquet column name requirements. 
We use the Schema file to perform that mapping, hence we are using the Schema file to compare pre-transformed column names with Delta and SQL column names. 
"""
dfRawColumns = dfJson.select("OriginalColumnName").rdd.flatMap(lambda x: x).collect()
dfSQLColumns = removeSqlDataLineageColumns(dfSQLColumn.columns)
dfDeltaColumns = dfDelta.columns

# set columnNameComparisonTestPass to pass initially 
columnNameComparisonTestPass = True
for index in range(len(dfSQLColumns)): 
  if dfRawColumns[index] == dfSQLColumns[index] == dfDeltaColumns[index]:
    pass # do nothing 
  else:
    columnNameComparisonTestPass = False
    
if columnNameComparisonTestPass:
  print("[Test] Column Name Comparison: PASSED")
else:
  print("[Test] Column Name Comparison: FAILED")

# check overall tests and raise errors if any test failed 
if not rowCountTestPassed or not columnCountTestPass or not columnNameComparisonTestPass:
  raise Exception("One or more tests have failed. Please review the test results above.")

# COMMAND ----------

# MAGIC %md
# MAGIC ##### Test Complete
# MAGIC Review test results above