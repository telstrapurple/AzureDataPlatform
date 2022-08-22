# Databricks notebook source
# MAGIC %md
# MAGIC #### Generic Python Functions used by Generic File Load Notebooks

# COMMAND ----------

# DBTITLE 1,Import the generic libraries
from pyspark.sql import functions
from pyspark.sql.types import *
from pyspark.sql.functions import *
import chardet
import json
import requests
import distutils.util
from requests.auth import HTTPBasicAuth
from pyspark.sql.functions import lit, col
from datetime import datetime
from pyspark.sql import functions as F

# COMMAND ----------

# DBTITLE 1,Function to remove all files in a directory that don't match a given extension
def removeUnwantedFiles(filePath, fileType):
  fileFolder = dbutils.fs.ls(filePath)
  for ff in fileFolder: 
    if ff.path.endswith("/"):
      fileList = dbutils.fs.ls(ff)
      for file in fileList: 
        if not file.path.endswith("." + fileType):
          dbutils.fs.rm(file.path)
    else:
      for ff in fileFolder: 
        if not ff.path.endswith("." + fileType):
          dbutils.fs.rm(ff.path)

# COMMAND ----------

# DBTITLE 1,Function to write a dataframe to SQL using the JDBC driver
def writeDataframeToSQL(dataFrame, targetDatabaseName, targetTable, writeMode):
  
  #Create connection properties for SQLDB using JDBC
  sqlUserName = spark.conf.get("sqlUserName")
  sqlPassword = spark.conf.get("sqlPassword")
  sqlHostName = spark.conf.get("sqlHostName")
  sqlDatabase = targetDatabaseName
  sqlPort = spark.conf.get("sqlPort")

  #Create the JDBC URL without passing in the user and password parameters.
  jdbcUrl = "jdbc:sqlserver://{0}:{1};database={2}".format(sqlHostName, sqlPort, sqlDatabase)

  #Create a Properties() object to hold the parameters.
  connectionProperties = {
    "user" : sqlUserName,
    "password" : sqlPassword,
    "driver" : "com.microsoft.sqlserver.jdbc.SQLServerDriver"
  }

  #Write the data frame table to SQL
  dataFrame.write.jdbc(url=jdbcUrl, table=targetTable, mode=writeMode.lower(), properties=connectionProperties)

# COMMAND ----------

# DBTITLE 1,Function to determine the folder based on the time prefix in the folder path
def getSourceFolderSuffix(fileName):
  maxLength = len(fileName)
  folderPath = fileName[maxLength-11:maxLength]
  if(folderPath.replace("/", "").isnumeric() == True and len(folderPath.replace("/", "")) == 8):
    return(folderPath)
  else:
    return("")

# COMMAND ----------

# DBTITLE 1,Function to determine the folder based on the time prefix in the file name
def getFolderPathFromPrefix(filePrefixFormat, fileName):
  if(filePrefixFormat.upper() == "YYYYMMDD"):
    folderPath = fileName[0:4] + "/" + fileName[4:6] + "/" + fileName[6:8]
    return(folderPath)
  elif(filePrefixFormat.upper() == "YYYYMM"):
    folderPath = fileName[0:4] + "/" + fileName[4:6]
    return(folderPath)
  elif(filePrefixFormat.upper() == "YYYY"):
    folderPath = fileName[0:4]
    return(folderPath)

# COMMAND ----------

# DBTITLE 1,Function to determine encoding type for delimited files
def getEncodingType(sourceFilePath, fileMask, loadType, fileFormat):
  # sourceFilePath = sourceFilePath.replace('dbfs:', '/dbfs')
  # get first file in folder 
  sourceFilePath = glob.glob(sourceFilePath + "**", recursive=True)
  for fileName in sourceFilePath: 
    if((fileMask.upper() in fileName.upper() or fileMask == "*") and fileName.upper().endswith(fileFormat.upper())): 
      sourceFilePathPython = fileName
      break # stop loop from running 
  # read source file. Only read first 500 rows to handle large files
  count = 0
  testStr = b''
  with open(sourceFilePathPython, 'rb') as file:
    line = file.readline()
    while line and count < 500:
      testStr = testStr + line
      count = count + 1
      line = file.readline()
  # determine file encoding of source file 
  detectFileEncoding = chardet.detect(testStr)
  ## Uncomment below for a more generic checker 
  if detectFileEncoding['confidence'] > 0.9 : 
    return detectFileEncoding['encoding']
  else:
    return 'UTF-8'

# COMMAND ----------

# DBTITLE 1,Function to remove trailing \r due to Spark multiLine option (to be fixed in release of Spark 3.0)
def removeMultiLineCR(df):
  # Get the data types
  datatypes = [f.dataType for f in df.schema.fields]
  # Get last column 
  lastColumn = df.columns[-1]
  # If last column is not StringType then cast last column as string 
  if datatypes[-1] != StringType:
    dfTemp = df.withColumn(df.columns[-1], df[df.columns[-1]].cast("string"))
  # Get last column first row 
  lastColumnFirstRow = dfTemp.first()[dfTemp.columns[-1]]
  # if column contains \r then remove \r from last column and return new df 
  if "\r" in lastColumnFirstRow and "\r" in lastColumn:
    lastColumn = lastColumn[:-1]
    lastColumnCR = lastColumn + "\r"
    # rename column 
    df = df.withColumnRenamed(lastColumnCR,lastColumn)
    # replace column that contains \r with new column without \r 
    df = df.withColumn(lastColumn,expr("substring(" + lastColumn + ", 0, length(" + lastColumn + ")-1)"))
  # else return original df without changes  
  return df 

# COMMAND ----------

# DBTITLE 1,Function to process delimited files
def processDelimitedFile(sourceFilePath, parquetFilePath, csvFilePath, header, delimiter, schema, fileMask, loadType, fileFormat):
  if(header.upper() == "Y"):
    header = "true"
  else:
    header = "false"
  
  #Get encoding type
  encodingType = getEncodingType(sourceFilePath, fileMask, loadType, fileFormat)
  #Read the delimited file. Use the schema if it has been specified
#   encodingType = "UTF-8"
  
  if(len(schema) > 0):
    schema = eval(schema)
    dfSource = sqlContext.read.format("csv").options(header=header, inferSchema="false", delimiter=delimiter, encoding=encodingType,escape='"',multiline="true").schema(schema).load(sourceFilePath) 
  else:
    dfSource = sqlContext.read.format("csv").options(header=header, inferSchema="true", delimiter=delimiter, encoding=encodingType,escape='"',multiline="true").load(sourceFilePath) 
  # change column/schema in dfSource
  dfSource = replaceInvalidColumnName(dfSource)
  # Remove trailing \r if exists in last column -- note that we can remove this line of code when Spark 3.0 is released 
  dfSource = removeMultiLineCR(dfSource)
  #Write the file to parquet
  dfSource.write.parquet(parquetFilePath, mode="overwrite")
  #Remove the unwanted files
  removeUnwantedFiles(parquetFilePath, "parquet")
  #Write the csv data to the staging area. Only write a single CSV file
  dfSource.repartition(1).write.csv(csvFilePath, mode="overwrite", header="true", nullValue="", escape='"')
  #Remove the unwanted files
  removeUnwantedFiles(csvFilePath, "csv")

# COMMAND ----------

# DBTITLE 1,Function to convert struct type data into json strings
def convertStructTypeToJson(df):
  for item in range(len(df.schema)):
    # Checking if struct exist in column, if so then convert column to JSON 
    if "struct" in df.schema[item].dataType.simpleString():
      # Convert StructType object to JSON string 
      df = df.withColumn(df.columns[item],functions.to_json(functions.struct(functions.col(df.columns[item]))))     
  return df

# COMMAND ----------

# DBTITLE 1,Function to process json files
def processJsonFile(sourceFilePath, parquetFilePath, csvFilePath, schema, fileMask, loadType, fileFormat):
  #Get encoding type
  encodingType = getEncodingType(sourceFilePath, fileMask, loadType, fileFormat)
  # Convert schema string to python schema object 
  schema = eval(schema)
  #Read the json
  dfSource = spark.read.options(multiline="true", encoding=encodingType).json(sourceFilePath, schema)
  # change column/schema in dfSource
  dfSource = replaceInvalidColumnName(dfSource)
  #Write the file to parquet
  dfSource.write.parquet(parquetFilePath, mode="overwrite")
  #Remove the unwanted files
  removeUnwantedFiles(parquetFilePath, "parquet")
  #Convert StructType objects to JSON strings in columns
  dfSource = convertStructTypeToJson(dfSource)
  #Write the csv data to the staging area
  dfSource.write.csv(csvFilePath, mode="overwrite", header="true", nullValue="", escape='"')
  #Remove the unwanted files
  removeUnwantedFiles(csvFilePath, "csv")

# COMMAND ----------

# DBTITLE 1,Function to replace invalid column names
def replaceInvalidColumnName(dfSource):
  # get columns in dataframe 
  columns = dfSource.columns
  # for each column, replace characters that should not exist in column name with blank 
  for i in range(0,len(columns)): 
    columns[i] = replaceString(columns[i])
  # rename each column in the dataframe with the amended column names 
  for i in range(0,len(columns)): 
    dfSource=dfSource.withColumnRenamed(dfSource.columns[i], columns[i])
  return dfSource

# COMMAND ----------

# DBTITLE 1,Function to find and replace characters that should not be used in column names
def replaceString(string):
  replaceCharacters = " .,;{}()\n\t\r=" 
  for i in replaceCharacters: 
    string = string.replace(i,'')
  return string

# COMMAND ----------

# DBTITLE 1,Function to copy the files into /mnt/tmp
def copyFileToTmp(loadFileName, fileList, fileMask, loadType, fileFormat):
  sourceFileList = []
  sourceFolderPath = [] 
  i = 1
  # Loop through each fileName in the fileList
  for fileName in fileList:    
    # Check if the conditions are TRUE and if so, then execute next statements below 
    if((fileMask.upper() in fileName.upper() or fileMask == "*") and fileName.upper().endswith(fileFormat.upper())): 
      if(loadType == "FILE" and i == 1):
        # Get file name
        fileName = fileName.replace("/dbfs", "") 
        #Add the file to the new list
        sourceFileList.append(fileName)
      elif loadType == "FOLDER":
        # Get file name
        fileName = fileName.replace("/dbfs", "") 
        #Add the file to the new list
        sourceFileList.append(fileName)
      i = i + 1
  #Get the target file path
  targetPathObject = dbutils.fs.ls(sourceFileList[0])
  targetPath = targetPathObject[0].path.replace(targetPathObject[0].name,"").replace("/mnt", "/tmp/fileLoad")
  #Clean out the target path before copying new files
  dbutils.fs.rm(targetPath, True)
  for sourceFileName in sourceFileList:
    # Get the target path 
    targetPath = sourceFileName.replace("/mnt", "/tmp/fileLoad")
    # print(targetPath)
    # Copy file into /mnt/temp/ folder
    dbutils.fs.cp(sourceFileName, targetPath, True)
    # Get target object 
    targetObject = dbutils.fs.ls(targetPath)
    # Get source folder path 
    targetFolderPath = targetObject[0].path.replace(targetObject[0].name,"")
    # Adding folder path to sourceFolderPath list 
    if targetFolderPath not in sourceFolderPath:
      sourceFolderPath.append(targetFolderPath)
    
  return sourceFileList, sourceFolderPath

# COMMAND ----------

# DBTITLE 1,Function to get source file paths (only paths that include files)
def getSourceFilePath(fileList, fileMask, loadType, fileFormat):
  sourceFilePath = []
  i = 1
  for fileName in fileList: 
    if((fileMask.upper() in fileName.upper() or fileMask == "*") and fileName.upper().endswith(fileFormat.upper())): 
      file = dbutils.fs.ls(fileName.replace("/dbfs", ""))
      # get the sourceFilePath. file[0] obtains the object from the list. 
      filePath = file[0].path.replace(file[0].name, "")
      # obtain the source folder prefix. file[0] obtains the object from the list.
      if(loadType == "FILE" and i == 1):
        sourceFilePath.append(filePath)
      elif(loadType == "FOLDER" and filePath not in sourceFilePath):
        sourceFilePath.append(filePath)
      i = i + 1
  return sourceFilePath

# COMMAND ----------

# DBTITLE 1,Function to get the SQL create statement based on a dataframe schema
def getSQLCreateScript(dataFrame, targetTable):
  sql = "CREATE TABLE " + targetTable + "("
  for columns in dataFrame.dtypes:
    if columns[1].lower() == "binary":
      dataType = "VARBINARY(MAX)"
    else:
      dataType = "NVARCHAR(MAX)"
    sql += "[" + columns[0] + "] " + dataType + ","
  sql = sql[0:-1] + ")"
  return sql

# COMMAND ----------

# DBTITLE 1,Function to get the SQL create statement based on a dataframe schema. Use data types and column names from the task schema
def getSQLCreateScriptTaskSchema(dataFrame, targetTable, taskSchema, addDataLineage, addETLOperation):
  sql = "CREATE TABLE " + targetTable + "("
  for tableColumn in dataFrame.dtypes:
    for schemaColumn in taskSchema:
      if schemaColumn.get("TransformedColumnName") == tableColumn[0]:
        sql += "[" + schemaColumn.get("OriginalColumnName") + "] " + schemaColumn.get("SQLDataType") + ","
  if addDataLineage == "Y" and addETLOperation == "Y":
    sql = sql[0:-1] + ",[ETL_Operation] VARCHAR(50), [ADS_TaskInstanceID] INT, [ADS_DateCreated] DATETIMEOFFSET)"
  elif addDataLineage == "Y" and addETLOperation == "N":
    sql = sql[0:-1] + ",[ADS_TaskInstanceID] INT, [ADS_DateCreated] DATETIMEOFFSET)"
  else:
    sql = sql[0:-1] + ")"
  return sql

# COMMAND ----------

# DBTITLE 1,Function to get the SQL create statement based on a dataframe schema for SQL DW
def getSQLCreateScriptDW(dataFrame, targetTable):
  sql = "CREATE TABLE " + targetTable + "("
  for columns in dataFrame.dtypes:
    if columns[1].lower() == "binary":
      dataType = "VARBINARY(8000)"
    else:
      dataType = "NVARCHAR(4000)"
    sql += "[" + columns[0] + "] " + dataType + ","
  sql = sql[0:-1] + ")"
  return sql

# COMMAND ----------

# DBTITLE 1,Function to check if libraries are installed 
def adbAPI(endPoint, body, method, region, token):
  """Execute HTTP request against Databricks REST API 2.0"""
  domain = region + ".azuredatabricks.net"
  baseURL = "https://%s/api/" % (domain)

  if method.upper() == "GET":
    response = requests.get(
        baseURL + endPoint
      , auth = HTTPBasicAuth("token", token)
      , json = body
    )
  else:
    response = requests.post(
        baseURL + endPoint
      , auth = HTTPBasicAuth("token", token)
      , json = body
    )
  
  return response

def describeClusterLibraryState(source, clusterId, status):
  """Converts cluster library status response to a verbose message"""
  
  result_map = {
      "NOT_INSTALLED"       : "{} library is not installed on cluster {}.".format(source.title(), clusterId)
    , "INSTALLED"           : "{} library is already installed on cluster {}.".format(source.title(), clusterId)
    , "PENDING"             : "Pending installation of {} library on cluster {} . . .".format(source, clusterId)
    , "RESOLVING"           : "Retrieving metadata for the installation of {} library on cluster {} . . .".format(source, clusterId)
    , "INSTALLING"          : "Installing {} library on cluster {} . . .".format(source, clusterId)
    , "FAILED"              : "{} library failed to install on cluster {}.".format(source.title(), clusterId)
    , "UNINSTALL_ON_RESTART": "{} library installed on cluster {} has been marked for removal upon cluster restart.".format(source.title(), clusterId)
  }

  return result_map[status.upper()]

def getClusterLibraryStatus(source, properties, dbRegion, dbToken, verbose = True):
  """Gets the current library status """
  
  source = source.lower()

  # Get the cluster ID from the Spark environment
  clusterId = spark.conf.get("spark.databricks.clusterUsageTags.clusterId")

  # Set default result to not installed
  result = describeClusterLibraryState(source, clusterId, "NOT_INSTALLED") if verbose else "NOT_INSTALLED" 

  # Execute REST API request to get the library statuses
  libStatuses = adbAPI("2.0/libraries/cluster-status?cluster_id=" + clusterId, None, "GET", dbRegion, dbToken)
  
  if libStatuses.status_code == 200:
    statuses = libStatuses.json()
    if "library_statuses" in statuses:
      for status in statuses["library_statuses"]:
        if status["library"] == {source: properties}:
          if verbose:
            result = describeClusterLibraryState(source, clusterId, status["status"])
          else:
            result = status["status"]
            
  return result

# COMMAND ----------

# DBTITLE 1,Function to add columns and generate insert and update statements for Delta Lake tables
def addDeltaLakeColumns(dfCurrent, targetTable, allowSchemaDrift):
  # Set the current database context
  spark.sql("USE ADS_Delta_Lake")
  # Get the current data frame schema as well as the target table schema
  currentSchemaInfo = dfCurrent.dtypes
  tableSchema = spark.sql("DESCRIBE " + targetTable).collect()
  newColumnList = ""
  newColumnNameList = ""
  errorMessage = ""
  insertStatement = "INSERT("
  insertValues = "VALUES("
  updateStatement = "UPDATE SET "
  # Loop through all the columns to check for new ones not in the delta lake table
  for currentColumn in currentSchemaInfo:
    columnExists = False
    updateStatement += currentColumn[0] + " = " + "Source." + currentColumn[0] + ","
    for tableColumn in tableSchema:
      if currentColumn[0] == tableColumn["col_name"]:
        columnExists = True
        break # Column exists so exit loop
    if columnExists == False:
      newColumnList += currentColumn[0] + " " + currentColumn[1] + ","
      newColumnNameList += currentColumn[0] + ","
  if newColumnList != "":
    if allowSchemaDrift == "Y":
      newColumnList = newColumnList[:-1]
      spark.sql("ALTER TABLE " + targetTable + " ADD COLUMNS (" + newColumnList + ")")
    elif allowSchemaDrift == "N":
      newColumnNameList = newColumnNameList[:-1]
      errorMessage = "Schema drift not allowed and column/s added/renamed in " + targetTable + ": " + newColumnNameList
      
  # Loop through all the columns to build up the insert statement for the Delta Lake merge
  tableSchema = spark.sql("DESCRIBE " + targetTable).collect()
  for tableColumn in tableSchema:
    columnExists = False
    insertStatement += tableColumn["col_name"] + ","
    for currentColumn in currentSchemaInfo:
      if tableColumn["col_name"] == currentColumn[0]:
        columnExists = True
        break # Column exists so exit loop
    if columnExists == True:
      insertValues += "Source." + currentColumn[0] + ","
    else:
      insertValues += "NULL,"
  insertValues = insertValues[:-1] + ")"
  insertStatement = insertStatement[:-1] + ") " + insertValues
  updateStatement = updateStatement[:-1]
  return insertStatement, updateStatement, errorMessage

# COMMAND ----------

# DBTITLE 1,Function to perform delta lake load
def deltaLakeLoad(useDeltaLakeIndicator, targetTable, targetDeltaFilePath, deltaLakeRetentionDays, uniqueConstraintIndicator, uniqueConstraintColumns, tempTableName, dfCurrent):
  # Get variables
  global_temp_db = spark.conf.get("spark.sql.globalTempDatabase")
  if useDeltaLakeIndicator == "Y": # Check if we need to do a delta lake load
    tableExists = "N"
    #Remove the ETL_Operation column from dfCurrent if it exists
    if "ETL_Operation" in dfCurrent.columns:
      dfCurrent = dfCurrent.drop("ETL_Operation")
    # Set the database context to Delta Lake
    try: # Create the Delta Lake database if it doesn't exist
      spark.sql("USE ADS_Delta_Lake")
    except:
      spark.sql("CREATE DATABASE ADS_Delta_Lake")
      spark.sql("USE ADS_Delta_Lake")
    # Write the current data frame as a delta table
    try:
      spark.sql(f"DESCRIBE {targetTable}")
      tableExists = "Y"
    except:
      dfCurrent.write.format("delta").save(targetDeltaFilePath)
      # Create the table if it doesn't exist
      spark.sql(f"CREATE TABLE IF NOT EXISTS {targetTable} USING DELTA LOCATION '{targetDeltaFilePath}'")
      # Set the log retention period
      spark.sql(f"ALTER TABLE {targetTable} SET TBLPROPERTIES(delta.logRetentionDuration='interval {deltaLakeRetentionDays} days', delta.deletedFileRetentionDuration = 'interval {deltaLakeRetentionDays} days',delta.autoOptimize.autoCompact = true)")
      return True
    
    
    if tableExists == "Y" and uniqueConstraintIndicator == "N": # The delta table already exists so overwrite it as there is no key
      dfCurrent.write.format("delta").mode("overwrite").option("mergeSchema", "true").save(targetDeltaFilePath) 
      #Vacuum the table to clean up old files
      spark.sql(f"VACUUM {targetTable} RETAIN {int(deltaLakeRetentionDays)*24} HOURS")
      return True
    elif tableExists == "Y" and uniqueConstraintIndicator == "Y": # There is a key so perform a MERGE
      insertStatement, updateStatement, errorMessage = addDeltaLakeColumns(dfCurrent, targetTable, allowSchemaDrift)
      if errorMessage != "": # There was schema drift error to return it to ADF
        return str(errorMessage)
      else:  
        targetDeltaMergeJoin = ""
        # Generate the join statement
        for uniqueColumn in uniqueConstraintColumns.split(","):
          targetDeltaMergeJoin += f"Source.{uniqueColumn} = Target.{uniqueColumn} AND "
        targetDeltaMergeJoin = targetDeltaMergeJoin[:-5]
        mergeStatement = f"MERGE INTO {targetTable} AS Target USING {global_temp_db}.{tempTableName} AS Source ON {targetDeltaMergeJoin}"
        if uniqueConstraintIndicator == "Y": # Only do delete for datasets with key constraints  
          mergeStatement += " WHEN MATCHED AND Source.ETL_Operation = 'Delete' THEN DELETE"
          mergeStatement += f" WHEN MATCHED AND Source.ETL_Operation in('Update', 'Insert') THEN {updateStatement}"
        else: # no key constraint  
          mergeStatement += f" WHEN MATCHED THEN {updateStatement}"
        mergeStatement += f" WHEN NOT MATCHED THEN {insertStatement}"
        spark.sql(mergeStatement)
        #Vacuum the table to clean up old files
        spark.sql(f"VACUUM {targetTable} RETAIN {int(deltaLakeRetentionDays)*24} HOURS")
        return True  
  else:
    return True

# COMMAND ----------

# DBTITLE 1,Functions related to CDC data loads
def getCDCDataframe(targetFilePath, previousTargetFilePath, targetFileFormat, previousTargetFileFormat):
  """
  Read current and previous dataframes
  ---
  Input: 
  - targetFilePath: the current file path 
  - previousTargetFilePath: the previous file path 
  - targetFileFormat: the file format for the current file path 
  - previousTargetFilePath: the file format for the previous file path 
  """
  # Read source parquet files 
  currentDf = spark.read.format(targetFileFormat).load(targetFilePath)
  # Get schema 
  sourceSchema = currentDf.schema
  # Read the previous source file
  previousDf = spark.read.format(previousTargetFileFormat).schema(sourceSchema).load(previousTargetFilePath)
  return currentDf, previousDf

def getCDCDataframeDelta(targetFilePath, previousTargetFilePath, targetFileFormat, previousTargetFileFormat):
  """
  Read current and previous dataframes
  ---
  Input: 
  - targetFilePath: the current file path 
  - previousTargetFilePath: the previous file path 
  - targetFileFormat: the file format for the current file path 
  - previousTargetFilePath: the file format for the previous file path 
  """
  # Read source parquet files 
  currentDf = spark.read.format(targetFileFormat).load(targetFilePath)
  # Read the previous source file
  previousDf = spark.read.format(previousTargetFileFormat).load(previousTargetFilePath)
  # drop columns from previous that don't exist in source 
  columnsToDrop = []
  for previousColumn in previousDf.dtypes:
    found = False 
    for currentColumn in currentDf.dtypes:
      if previousColumn[0] == currentColumn[0]:
        found = True 
    if found == False: 
      columnsToDrop.append(previousColumn[0])
  previousDf = previousDf.drop(*columnsToDrop)
  # add columns to previous that exist in current  
  columnsToAdd = [] 
  for currentColumn in currentDf.dtypes: 
    found = False
    for previousColumn in previousDf.dtypes:
      if currentColumn[0] == previousColumn[0]:
        found = True
    if found == False:
      columnsToAdd.append(currentColumn)
  for column in columnsToAdd: 
    previousDf = previousDf.withColumn(column[0], lit(None).cast(column[1]))
  
  return currentDf, previousDf

def getDataframe(targetFilePath, fileFormat): 
  # Read source parquet files 
  currentDf = spark.read.format(fileFormat).load(targetFilePath)
  return currentDf

def getCDCKeyColumn(dataframe, tableName, columnName, includeAlias):
  # Get the data frame data types
  columns = dataframe.dtypes
  # Create arrays for the numeric data types
  numericArray = ["short","long","decimal","decimal(38,18)","double","int","float","boolean"]
  returnString = ""
  for column in columns:
    if column[0] in columnName:
      if column[1] in numericArray:
        if tableName != "":
          returnString = "ifNull(" + tableName + "." + columnName + ", 0)"
        else:
          returnString = "ifNull(" + columnName + ", 0)"
      elif column[1] == "binary":
        if tableName != "":
          returnString = "ifNull(" + tableName + "." + columnName + ", CAST('' AS BINARY))"
        else:
          returnString = "ifNull(" + columnName + ", CAST('' AS BINARY))"
      else:
        if tableName != "":
          returnString = "ifNull(" + tableName + "." + columnName + ", '')"
        else:
          returnString = "ifNull(" + columnName + ", '')"
      if includeAlias == "Y":
        return returnString + " AS " + columnName
      else:
        return returnString

def cdc(dfCurrent, dfPrevious, tempTableName, uniqueConstraintColumns, returnType="merge"):
  # Create temp tables for the source and target data frames
  dfCurrent.createOrReplaceTempView(tempTableName + "_Current")
  dfPrevious.createOrReplaceTempView(tempTableName + "_Previous")
  
  # Initialise variables
  keyJoin = ""
  previousKeyJoin = ""
  currentKeyJoin = ""
  uniqueColumnList = ""

  # Build up the select and key join queries
  for uniqueColumn in uniqueConstraintColumns.split(","):
      keyJoin += getCDCKeyColumn(dfCurrent, "Current", uniqueColumn, "N") + " = " + getCDCKeyColumn(dfCurrent, "Keys", uniqueColumn, "N") + " AND "
      previousKeyJoin += getCDCKeyColumn(dfCurrent, "Previous", uniqueColumn, "N") + " = " + getCDCKeyColumn(dfCurrent, "PreviousKey", uniqueColumn, "N") + " AND "
      currentKeyJoin += getCDCKeyColumn(dfCurrent, "Current", uniqueColumn, "N") + " = " + getCDCKeyColumn(dfCurrent, "CurrentKey", uniqueColumn, "N") + " AND "
      uniqueColumnList += getCDCKeyColumn(dfCurrent, "", uniqueColumn, "Y") + ","
  keyJoin = keyJoin[:-5]
  previousKeyJoin = previousKeyJoin[:-5]
  currentKeyJoin = currentKeyJoin[:-5]
  uniqueColumnList = uniqueColumnList[:-1]
  # Get the deleted records
  dfDelete = spark.sql("SELECT Previous.*, 'Delete' AS ETL_Operation FROM " + tempTableName + "_Previous Previous INNER JOIN " + 
                       "(SELECT " + uniqueColumnList + " FROM " + tempTableName + "_Previous EXCEPT SELECT " + uniqueColumnList + " FROM " + tempTableName + "_Current) PreviousKey ON " + previousKeyJoin)
  dfInsert = spark.sql("SELECT Current.*, 'Insert' AS ETL_Operation FROM " + tempTableName + "_Current Current INNER JOIN " + 
                       "(SELECT " + uniqueColumnList + " FROM " + tempTableName + "_Current EXCEPT SELECT " + uniqueColumnList + " FROM " + tempTableName + "_Previous) CurrentKey ON " + currentKeyJoin)
  dfUpdate = spark.sql("SELECT Current.*, 'Update' AS ETL_Operation FROM " + tempTableName + "_Current Current INNER JOIN " + 
                       "(SELECT * FROM " + tempTableName + "_Current EXCEPT SELECT * FROM " + tempTableName + "_Previous) CurrentKey ON " + currentKeyJoin + " INNER JOIN " + 
                       tempTableName + "_Previous Previous ON " + keyJoin.replace("Keys.", "Previous."))
  
  if returnType=="merge": 
    dfUnion = dfDelete.unionAll(dfInsert).unionAll(dfUpdate)
  elif returnType =="upsert": 
    dfUnion = dfInsert.unionAll(dfUpdate)
  else: 
    raise Exception("return type not supported")
  return dfUnion

# COMMAND ----------

# DBTITLE 1,Function to write history table to the data lake
def writeHistoryTableToDataLake(df, rawStorageAccountURIPath, taskInstanceId):
  """
  Writes the history table to the data lake 
  ---
  Inputs:
  - df: union or current dataframe
  - rawDataLakeFilePath: the raw data lake file path 
  - taskInstanceId: the task instance id 
  """
  # add new column for task instance id 
  df = df.withColumn("ADS_TaskInstanceID", lit(taskInstanceId))
  # add new column for timestamp 
  df = df.withColumn("ADS_DateCreated", lit(datetime.now().strftime("%Y-%m-%d %H:%M:%S %z")))
  historyStorageAccountURIPath = rawStorageAccountURIPath.replace("Raw", "History")
  df.write.parquet(historyStorageAccountURIPath, mode="overwrite")
  removeUnwantedFiles(historyStorageAccountURIPath, "parquet")

# COMMAND ----------

# DBTITLE 1,Function to Generate dataframe and temp views for first load assuming the dataset has a primary key. Writes history table to data lake if required.
def generateFirstLoad(targetStorageAccountURIPath, targetFileFormat, targetTempTable, tempTableName, historyTable, taskInstanceID, taskType, taskSchema):
  """
  Generate dataframe and temp views for first load. The dataset has a primary key. Write history table to data lake if required. 
  ---
  Inputs: 
  - targetStorageAccountURIPath: target storage account uri path 
  - targetFileFormat: file format for the target uri path e.g. 'parquet' or 'delta'
  - targetTempTable: target temp table to write to
  - tempTableName: tempTableName used only within Databricks 
  - historyTable: Boolean String ["True", "False"] to indicate whether history table is required or not
  - taskInstanceID: task instance ID of the load
  - taskType: task type of the load
  - taskSchema: task schema of the load
  ---
  Outputs:
  - Returns dfCurrent as it is used for delta lake load 
  """
  # Get dfCurrent
  dfCurrent = getDataframe(targetStorageAccountURIPath, targetFileFormat) 
  if "to DW Stage" in taskType:
    dfSchema = dfCurrent
    # Change the data frame data types
    dfSchema = changeDFDataTypes(dfSchema, taskSchema)
    # Rename the columns in the data frame
    dfSchema = renameDFColumnsFromSchema(dfSchema, taskSchema)  
    # Add the TaskInstanceID and Date Created columns     
    dfSchema = dfSchema.withColumn("ETL_Operation", lit("Insert")).withColumn("ADS_TaskInstanceID", lit(taskInstanceID).cast("integer")).withColumn("ADS_DateCreated", lit(datetime.now().strftime("%Y-%m-%d %H:%M:%S %z")))
    # Generate the SQL script to create the temp table
    createSQLStatement = getSQLCreateScriptTaskSchema(dfCurrent, targetTempTable, taskSchema, "Y", "Y")    
    # Create a temp table for the data
    dfSchema.createOrReplaceGlobalTempView(tempTableName)
  else:
    # Add ETL_Operation column with only inserts
    dfCurrent = dfCurrent.withColumn("ETL_Operation", lit("Insert"))
    # Generate the SQL script to create the temp table
    createSQLStatement = getSQLCreateScript(dfCurrent, targetTempTable)
  # Create a temp table for the data
  dfCurrent.createOrReplaceGlobalTempView(tempTableName)
  # Add the SQL statement to a temporary table to pass to Scala
  dfSQL = spark.createDataFrame([[createSQLStatement]],StructType([StructField("createSQLStatement", StringType(),True)]))
  # Create a temp table for the schema
  dfSQL.createOrReplaceGlobalTempView(tempTableName + "_schema")
  if historyTable == "True":
    writeHistoryTableToDataLake(dfCurrent, targetStorageAccountURIPath, taskInstanceID) 
  
  return dfCurrent

# COMMAND ----------

# DBTITLE 1,Function to Generate dataframe and temp views for full, no key load. The dataset does NOT have a primary key. Write history table to data lake if required. 
def generateFullLoadNoKey(targetStorageAccountURIPath, targetFileFormat, targetTempTable, tempTableName, historyTable, taskInstanceID, taskType, taskSchema):
  """
  Generate dataframe and temp views for full, no key load. The dataset does NOT have a primary key. Write history table to data lake if required. 
  ---
  Inputs: 
  - targetStorageAccountURIPath: target storage account uri path 
  - targetFileFormat: file format for the target uri path e.g. 'parquet' or 'delta'
  - targetTempTable: target temp table to write to
  - tempTableName: tempTableName used only within Databricks 
  - historyTable: Boolean String ["True", "False"] to indicate whether history table is required or not
  - taskInstanceID: task instance ID of the load
  - taskType: task type of the load
  - taskSchema: task schema of the load
  ---
  Outputs:
  - Returns dfCurrent as it is used for delta lake load 
  """
  dfCurrent = getDataframe(targetStorageAccountURIPath, targetFileFormat) 
  if "to DW Stage" in taskType:
    dfSchema = dfCurrent
    # Change the data frame data types
    dfSchema = changeDFDataTypes(dfSchema, taskSchema)
    # Rename the columns in the data frame
    dfSchema = renameDFColumnsFromSchema(dfSchema, taskSchema)
    # Add ETL_Operation column with only inserts and add TaskInstanceID and Date Created columns
    dfSchema = dfSchema.withColumn("ETL_Operation", lit("Insert")).withColumn("ADS_TaskInstanceID", lit(taskInstanceID).cast("integer")).withColumn("ADS_DateCreated", lit(datetime.now().strftime("%Y-%m-%d %H:%M:%S %z")))
    # Generate the SQL script to create the temp table
    createSQLStatement = getSQLCreateScriptTaskSchema(dfCurrent, targetTempTable, taskSchema, "Y", "Y")
    # Create a temp table for the data
    dfSchema.createOrReplaceGlobalTempView(tempTableName)
  else:
    # Generate the SQL script to create the temp table
    createSQLStatement = getSQLCreateScript(dfCurrent, targetTempTable)
    # Create a temp table for the data
    dfCurrent.createOrReplaceGlobalTempView(tempTableName)
  # Add the SQL statement to a temporary table to pass to Scala
  dfSQL = spark.createDataFrame([[createSQLStatement]],StructType([StructField("createSQLStatement", StringType(),True)]))
  # Create a temp table for the schema
  dfSQL.createOrReplaceGlobalTempView(tempTableName + "_schema")
  
  return dfCurrent

# COMMAND ----------

# DBTITLE 1,Function to Generate dataframe and temp views for subsequent full loads. The dataset has a primary key. Write history table to data lake if required.
def generateSubsequentFullLoad(targetStorageAccountURIPath, previousTargetStorageAccountURIPath, targetFileFormat, previousTargetFileFormat, targetTempTable, tempTableName, historyTable, taskInstanceID, taskType, taskSchema):
  """
  Generate dataframe and temp views for subsequent full loads. The dataset has a primary key. Write history table to data lake if required. 
  ---
  Inputs: 
  - targetStorageAccountURIPath: target storage account uri path 
  - previousTargetStorageAccountURIPath: target storage account uri path 
  - targetFileFormat: file format for the target uri path e.g. 'parquet' or 'delta'
  - previousTargetFileFormat: file format for the target uri path e.g. 'parquet' or 'delta'
  - targetTempTable: target temp table to write to
  - tempTableName: tempTableName used only within Databricks 
  - historyTable: Boolean String ["True", "False"] to indicate whether history table is required or not
  - taskInstanceID: task instance ID of the load
  - taskType: task type of the load
  - taskSchema: task schema of the load
  ---
  Outputs:
  - Returns dfCurrent as it is used for delta lake load 
  """
  # Perform change data capture
  dfCurrent, dfPrevious = getCDCDataframe(targetStorageAccountURIPath, previousTargetStorageAccountURIPath, targetFileFormat, previousTargetFileFormat)
  # union add and delete DFs
  unionDf = cdc(dfCurrent, dfPrevious, tempTableName, uniqueConstraintColumns)
  if "to DW Stage" in taskType:
    # Change the data frame data types
    unionDf = changeDFDataTypes(unionDf, taskSchema)
    # Rename the columns in the data frame
    unionDf = renameDFColumnsFromSchema(unionDf, taskSchema) 
    # Add the TaskInstanceID and Date Created columns     
    unionDf = unionDf.withColumn("ADS_TaskInstanceID", lit(taskInstanceID).cast("integer")).withColumn("ADS_DateCreated", lit(datetime.now().strftime("%Y-%m-%d %H:%M:%S %z")))
    # Generate the SQL script to create the temp table
    createSQLStatement = getSQLCreateScriptTaskSchema(dfCurrent, targetTempTable, taskSchema, "Y", "Y")    
  else:
    # Generate the SQL script to create the temp table
    createSQLStatement = getSQLCreateScript(unionDf, targetTempTable)
  # Add the SQL statement to a temporary table to pass to Scala
  dfSQL = spark.createDataFrame([[createSQLStatement]],StructType([StructField("createSQLStatement", StringType(),True)]))
  # Create a temp table for the schema
  dfSQL.createOrReplaceGlobalTempView(tempTableName + "_schema")
  # Create a temp table for the data
  unionDf.createOrReplaceGlobalTempView(tempTableName) 
  if historyTable == "True":
    writeHistoryTableToDataLake(unionDf, targetStorageAccountURIPath, taskInstanceID)
  
  return dfCurrent 

# COMMAND ----------

# DBTITLE 1,Function to Generate dataframe and temp views for subsequent full loads. The dataset has a primary key. Write history table to data lake if required.
def generateSubsequentIncrementalLoad(targetStorageAccountURIPath, previousTargetStorageAccountURIPath, targetFileFormat, previousTargetFileFormat, targetTempTable, tempTableName, historyTable, taskInstanceID, whereClause, taskType, taskSchema):
  """
  Generate dataframe and temp views for subsequent full loads. The dataset has a primary key. Write history table to data lake if required. 
  ---
  Inputs: 
  - targetStorageAccountURIPath: target storage account uri path 
  - previousTargetStorageAccountURIPath: target storage account uri path (this should be the delta path)
  - targetFileFormat: file format for the target uri path e.g. 'parquet' or 'delta'
  - previousTargetFileFormat: file format for the target uri path e.g. 'parquet' or 'delta' (this should be delta)
  - targetTempTable: target temp table to write to
  - tempTableName: tempTableName used only within Databricks 
  - historyTable: Boolean String ["True", "False"] to indicate whether history table is required or not
  - taskInstanceID: task instance ID of the load
  - whereClause: the SQL WHERE clause used in the incremental load 
  - taskType: task type of the load
  - taskSchema: task schema of the load
  ---
  Outputs:
  - Returns dfCurrent as it is used for delta lake load 
  """
  # Perform change data capture
  dfCurrent, dfPrevious = getCDCDataframeDelta(targetStorageAccountURIPath, previousTargetStorageAccountURIPath, targetFileFormat, previousTargetFileFormat)
  incrementalValue = whereClause.split(">=")[1].replace(" ", "").replace("'","")
  incrementalColumn = whereClause.split("[")[1].split("]")[0]
  dfPrevious = dfPrevious.where(col(incrementalColumn) >= incrementalValue)
  dfCurrent = dfCurrent.where(col(incrementalColumn) >= incrementalValue)
  # union add and delete DFs
  unionDf = cdc(dfCurrent, dfPrevious, tempTableName, uniqueConstraintColumns, returnType="upsert")
  if "to DW Stage" in taskType:
    # Change the data frame data types
    unionDf = changeDFDataTypes(unionDf, taskSchema)
    # Rename the columns in the data frame
    unionDf = renameDFColumnsFromSchema(unionDf, taskSchema)
    # Add the TaskInstanceID and Date Created columns     
    unionDf = unionDf.withColumn("ADS_TaskInstanceID", lit(taskInstanceID).cast("integer")).withColumn("ADS_DateCreated", lit(datetime.now().strftime("%Y-%m-%d %H:%M:%S %z")))
    # Generate the SQL script to create the temp table
    createSQLStatement = getSQLCreateScriptTaskSchema(dfCurrent, targetTempTable, taskSchema, "Y", "Y")    
  else:
    # Generate the SQL script to create the temp table
    createSQLStatement = getSQLCreateScript(unionDf, targetTempTable)
  # Add the SQL statement to a temporary table to pass to Scala
  dfSQL = spark.createDataFrame([[createSQLStatement]],StructType([StructField("createSQLStatement", StringType(),True)]))
  # Create a temp table for the schema
  dfSQL.createOrReplaceGlobalTempView(tempTableName + "_schema")
  # Create a temp table for the data
  unionDf.createOrReplaceGlobalTempView(tempTableName) 
  if historyTable == "True":
    writeHistoryTableToDataLake(unionDf, targetStorageAccountURIPath, taskInstanceID) 
  
  return dfCurrent

# COMMAND ----------

# DBTITLE 1,Function to Generate dataframe and temp views for first CDC load assuming the dataset has a primary key.
def generateFirstCDCLoad(targetStorageAccountURIPath, targetFileFormat, targetTempTable, tempTableName, taskInstanceID):
  """
  Generate dataframe and temp views for first load. The dataset has a primary key. Write history table to data lake if required. 
  ---
  Inputs: 
  - targetStorageAccountURIPath: target storage account uri path 
  - targetFileFormat: file format for the target uri path e.g. 'parquet' or 'delta'
  - targetTempTable: target temp table to write to
  - tempTableName: tempTableName used only within Databricks 
  - taskInstanceID: task instance ID of the load
  ---
  Outputs:
  - Returns dfCurrent as it is used for delta lake load 
  """
  # Get dfCurrent
  dfCurrent = getDataframe(targetStorageAccountURIPath, targetFileFormat) 
  # Add ETL_Operation column with only inserts
  dfCurrent = dfCurrent.withColumn("ETL_Operation", lit("Insert"))
  # Generate the SQL script to create the temp table
  createSQLStatement = getSQLCreateScript(dfCurrent, targetTempTable)
  # Add the SQL statement to a temporary table to pass to Scala
  dfSQL = spark.createDataFrame([[createSQLStatement]],StructType([StructField("createSQLStatement", StringType(),True)]))
  # Create a temp table for the schema
  dfSQL.createOrReplaceGlobalTempView(tempTableName + "_schema")
  # Create a temp table for the data
  dfCurrent.createOrReplaceGlobalTempView(tempTableName)
  
  return dfCurrent

# COMMAND ----------

# DBTITLE 1,Function to Generate history dataframe and temp views for first CDC history load assuming the dataset has a primary key. 
def generateFirstCDCHistoryLoad(targetStorageAccountURIPath, targetFileFormat, targetCDCStorageAccountURIPath, targetCDCFileFormat, targetTempTable, tempTableName, taskInstanceID):
  """
  Generate dataframe and temp views for first load. The dataset has a primary key. Write history table to data lake if required. 
  ---
  Inputs: 
  - targetStorageAccountURIPath: target storage account uri path 
  - targetFileFormat: file format for the target uri path e.g. 'parquet' or 'delta'
  - targetTempTable: target temp table to write to
  - tempTableName: tempTableName used only within Databricks 
  - taskInstanceID: task instance ID of the load
  ---
  Outputs:
  - Returns dfCurrent as it is used for delta lake load 
  """
  # Get dfCDC
  dfCDC = spark.read.format(targetCDCFileFormat).load(targetCDCStorageAccountURIPath)
  # Get schema 
  cdcSchema = dfCDC.schema
  # Get dfCurrent with dfCDC schema 
  dfCurrent = spark.read.format(targetFileFormat).schema(cdcSchema).load(targetStorageAccountURIPath)
  dfUnion = dfCurrent.unionAll(dfCDC)
  # Map __$operation to ETL_Operation using PySpark function due to better performance
  dfUnion = dfUnion.withColumn("ETL_Operation", F.when(dfUnion["__$operation"] == 1, "Delete").when(dfUnion["__$operation"]==2, "Insert").when(dfUnion["__$operation"]==4, "Update").when(dfUnion["__$operation"].isNull(), "Insert"))
  # comment-out above and uncomment below if native Python is preferred 
#   udf_mapETLOperation = udf(mapETLOperation)
#   dfUnion = dfUnion.withColumn("ETL_Operation", udf_mapETLOperation(dfUnion["__$operation"]))
  
  # Generate the SQL script to create the temp table
  createSQLStatement = getSQLCreateScript(dfUnion, targetTempTable)
  # Add the SQL statement to a temporary table to pass to Scala
  dfSQL = spark.createDataFrame([[createSQLStatement]],StructType([StructField("createSQLStatement", StringType(),True)]))
  # Create a temp table for the schema
  dfSQL.createOrReplaceGlobalTempView(tempTableName + "_schema")
  # Create a temp table for the data
  dfUnion.createOrReplaceGlobalTempView(tempTableName)  
  return dfUnion

# COMMAND ----------

# DBTITLE 1,Function to Generate dataframe and temp views for subsequent CDC load assuming the dataset has a primary key.
def generateSubsequentCDCLoad(targetStorageAccountURIPath, targetFileFormat, targetTempTable, tempTableName, taskInstanceID, history):
  """
  Generate dataframe and temp views for first load. The dataset has a primary key. Write history table to data lake if required. 
  ---
  Inputs: 
  - targetStorageAccountURIPath: target storage account uri path 
  - targetFileFormat: file format for the target uri path e.g. 'parquet' or 'delta'
  - targetTempTable: target temp table to write to
  - tempTableName: tempTableName used only within Databricks 
  - taskInstanceID: task instance ID of the load
  - history: boolean if the df is for a history or non-history table 
  ---
  Outputs:
  - Returns df as it is used for delta lake load 
  """
  # Get df
  df = getDataframe(targetStorageAccountURIPath, targetFileFormat)
  # Map __$operation to ETL_Operation using PySpark function due to better performance
  df = df.withColumn("ETL_Operation", F.when(df["__$operation"] == 1, "Delete").when(df["__$operation"]==2, "Insert").when(df["__$operation"]==4, "Update").when(df["__$operation"].isNull(), "Insert"))
  if not history:
    df = dropCDCMetadataColumns(df)
  # Generate the SQL script to create the temp table
  createSQLStatement = getSQLCreateScript(df, targetTempTable)
  # Add the SQL statement to a temporary table to pass to Scala
  dfSQL = spark.createDataFrame([[createSQLStatement]],StructType([StructField("createSQLStatement", StringType(),True)]))
  # Create a temp table for the schema
  dfSQL.createOrReplaceGlobalTempView(tempTableName + "_schema")
  # Create a temp table for the data
  df.createOrReplaceGlobalTempView(tempTableName)
  
  return df

# COMMAND ----------

# DBTITLE 1,Generic user defined function (UDF) to map CDC Operation to ETL Operation
# pySpark function is favored over native Python function due to pySpark being more optimised. 
def mapETLOperation(lsnOperation):
  if lsnOperation == 1:
    return "Delete"
  elif lsnOperation == 2:
    return "Insert"
  elif lsnOperation == 4:
    return "Update"
  elif lsnOperation == None:
    return "Insert"
  else:
    raise Exception("Unable to map ETL Operation")

# COMMAND ----------

# DBTITLE 1,Function to drop cdc metadata columns
def dropCDCMetadataColumns(df):
  columnsToDrop = ["__$start_lsn", "__$operation", "__$update_mask", "__$lsn_timestamp", "__$updated_columns"]
  df = df.drop(*columnsToDrop)
  return df

# COMMAND ----------

# DBTITLE 1,Function to break blob leases
def executeBreakBlobLease(serviceEndpoint, filePath,fileName): 
  functionAppBaseURL = spark.conf.get("functionAppBaseURL")
  if "/" != functionAppBaseURL[-1]:
    functionAppBaseURL + "/"
  functionAppURL = functionAppBaseURL + "/api/BreakBlobLease"

  headers={
    'x-functions-key': spark.conf.get("functionAppPowershellMasterKey")
  }

  data = {
    "serviceEndpoint":serviceEndpoint,
    "filePath":filePath,
    "fileName":fileName
  }

  response = requests.post(url=functionAppURL, headers=headers, json=data)
  try: 
    res = json.loads(response.text)
    res.get("Response")
    return res
  except:
    return "Could not obtain response."

# COMMAND ----------

# DBTITLE 1,Function to generate and overwrite the Staging Data Lake table by using a copy of the Delta Lake table 
def writeStagingDataLake(targetDeltaStorageAccountURIPath, targetStagingStorageAccountURIPath, targetStagingContainerFilePath, dataLakeStagingPartitions):
  """
  Generate dataframe and temp views for first load. The dataset has a primary key. Write history table to data lake if required. 
  A section of the code pertaining to Breaking Blob Leases is included. You may wish to uncomment this block of code out. Each blob will require 10-20 seconds for Azure Function to execute the break-blob command and 
  receive a response. From Microsoft documentation, only users with Write permission to the Data Lake can acquire leases: https://docs.microsoft.com/en-us/rest/api/storageservices/lease-blob#authorization.
  Thus if no Write access is granted to users in the Staging area, then it may not be required to break blob leases. 
  ---
  Inputs: 
  - targetDeltaStorageAccountURIPath: target delta lake storage account uri path 
  - targetStagingStorageAccountURIPath: target staging storage account 
  - targetStagingContainerFilePath: container and file path of the staging folder 
  - dataLakeStagingPartitions: number of partitions. If 0, then default to Spark's optimal partitioning.  
  ---
  """
      
  # Get dfDeltaLake
  dfDeltaLake = getDataframe(targetDeltaStorageAccountURIPath, "delta")
  try:
    if dataLakeStagingPartitions == 0:
      dfDeltaLake.write.parquet(targetStagingStorageAccountURIPath, mode="overwrite")
    else: 
      dfDeltaLake.repartition(dataLakeStagingPartitions).write.parquet(targetStagingStorageAccountURIPath, mode="overwrite")
  except:
    raise Exception("Unable to overwrite or write to the Storage Account Location: {targetStagingStorageAccountURIPath}. Please verify that no leases exist on the files.")
  
  # remove any unwanted files 
  removeUnwantedFiles(targetStagingStorageAccountURIPath, "parquet")

# COMMAND ----------

# DBTITLE 1,Function to generate an error if truncation occurs from source to target for numeric and decimal columns
def checkNumericTruncation(dataFrame, taskSchema, targetTempTable):
  columns = dataFrame.dtypes
  sqlSelectCheckScript = ""
  sqlHavingCheckScript = "HAVING "
  returnMessage = ""
  numericArray = ["long","decimal","decimal(38,18)","double","float"]
  for i in range(len(columns)):
    if columns[i][1] in numericArray and ("decimal" in taskSchema[i].get("SQLDataType").lower() or "numeric" in taskSchema[i].get("SQLDataType").lower()):
      targetDataType = taskSchema[i].get("SQLDataType")
      sqlSelectCheckScript += f"SUM(CASE WHEN CAST({columns[i][0]} AS {targetDataType}) <> {columns[i][0]} THEN 1 ELSE 0 END) AS {columns[i][0]},"
      sqlHavingCheckScript += f"SUM(CASE WHEN CAST({columns[i][0]} AS {targetDataType}) <> {columns[i][0]} THEN 1 ELSE 0 END) + "
  if sqlSelectCheckScript != "":
    dfCheck = spark.sql(f"SELECT {sqlSelectCheckScript[0:-1]} FROM {targetTempTable} {sqlHavingCheckScript[0:-2]} > 0")
  for column in dfCheck.columns:
    if float(dfCheck.select(column).first()[0]) > 0:
      returnMessage += f"Truncation has occurred for column {column}. Please check the source precision;"
  return returnMessage

# COMMAND ----------

# DBTITLE 1,Rename data frame columns based on task schema
def renameDFColumnsFromSchema(dataFrame, taskSchema):
  for tableColumn in dataFrame.dtypes:
    for schemaColumn in taskSchema:
      if schemaColumn.get("TransformedColumnName") == tableColumn[0] and schemaColumn.get("OriginalColumnName") != tableColumn[0]:
        dataFrame = dataFrame.withColumnRenamed(tableColumn[0], schemaColumn.get("OriginalColumnName")) 
  return dataFrame

# COMMAND ----------

# DBTITLE 1,Change data frame data types
def changeDFDataTypes(dataFrame, taskSchema):
  for tableColumn in dataFrame.dtypes:
    for schemaColumn in taskSchema:
      if "decimal" in schemaColumn.get("SQLDataType").lower():
        dataTypeName = schemaColumn.get("SQLDataType").split("(")[0]
        dataFrame = dataFrame.withColumn(schemaColumn.get("TransformedColumnName"),dataFrame[schemaColumn.get("TransformedColumnName")].cast(schemaColumn.get("SQLDataType")))
      elif "bigint" in schemaColumn.get("SQLDataType").lower():
        dataFrame = dataFrame.withColumn(schemaColumn.get("TransformedColumnName"),dataFrame[schemaColumn.get("TransformedColumnName")].cast("long"))
      elif "int" in schemaColumn.get("SQLDataType").lower():
        dataFrame = dataFrame.withColumn(schemaColumn.get("TransformedColumnName"),dataFrame[schemaColumn.get("TransformedColumnName")].cast("int"))
      elif "bit" in schemaColumn.get("SQLDataType").lower():
        dataFrame = dataFrame.withColumn(schemaColumn.get("TransformedColumnName"),dataFrame[schemaColumn.get("TransformedColumnName")].cast("boolean"))
  return dataFrame

# COMMAND ----------

# DBTITLE 1,Function to bulk load a SQL table from a Spark table using the Spark connector for SQL
def bulkCopyDBTableToSQLDB(sourceTable, targetDatabaseName, targetTable, writeMode, batchSize):
  try:
    df = spark.table(sourceTable)
    #Get the settings from config
    sqlUserName = spark.conf.get("sqlUserName")
    sqlPassword = spark.conf.get("sqlPassword")
    serverAddr = spark.conf.get("sqlHostName")
    sqlHostName = f"jdbc:sqlserver://{serverAddr}"
    url = sqlHostName + ";" + "databaseName=" + targetDatabaseName + ";"
    
    #Write the dataframe to SQL
    df.write \
      .format("com.microsoft.sqlserver.jdbc.spark") \
      .mode(writeMode) \
      .option("tableLock", "true") \
      .option("schemaCheckEnabled", "false") \
      .option("batchsize", batchSize) \
      .option("url", url) \
      .option("dbtable", targetTable) \
      .option("user", sqlUserName) \
      .option("password", sqlPassword) \
      .save()
  except ValueError as error :
    print("Connector write failed", error)

# COMMAND ----------

# DBTITLE 1,Function to bulk load a SQL table from a Spark table using the Spark connector for SQL. Use the provided connection details
def bulkCopyDBTableToSQLDBCustomConnection(sourceTable, targetDatabaseName, targetTable, writeMode, batchSize, sqlServerAddr, sqlUserName, sqlPassword):
  try:
    df = spark.table(sourceTable)
    #Get the settings from config
    sqlUserName = sqlUserName
    sqlPassword = sqlPassword
    sqlHostName = f"jdbc:sqlserver://{sqlServerAddr}"
    url = sqlHostName + ";" + "databaseName=" + targetDatabaseName + ";"
    
    #Write the dataframe to SQL
    df.write \
      .format("com.microsoft.sqlserver.jdbc.spark") \
      .mode(writeMode) \
      .option("tableLock", "true") \
      .option("schemaCheckEnabled", "false") \
      .option("batchsize", batchSize) \
      .option("url", url) \
      .option("dbtable", targetTable) \
      .option("user", sqlUserName) \
      .option("password", sqlPassword) \
      .save()
  except ValueError as error :
    print("Connector write failed", error)

# COMMAND ----------

# DBTITLE 1,Function to bulk load a Azure Synapse table from a Spark table using Azure SQL Data Warehouse connector for Azure Databricks
# #def bulkCopyDBTableToSQLDW(sourceTable, targetDatabaseName, targetTable, writeMode, batchSize):
# def bulkCopyDBTableToSQLDW(sourceTable, targetDatabaseName, targetTable, writeMode):
#   try:
#     df = spark.table(sourceTable)
#     #Get the settings from config
#     asaHostName = spark.conf.get("sqlHostName")
#     asaUserName = spark.conf.get("sqlUserName")
#     asaPassword = spark.conf.get("sqlPassword")
#     url = "jdbc:sqlserver://" + asaHostName + ";database=" + targetDatabaseName
#     targetTable = targetTable.replace("[","").replace("]","")
#     storageAcc = dbutils.secrets.get(scope = "datalakeconfig", key = "storageAccountDataLake")

#     tempDir = "abfss://datalakestore@" + storageAcc + ".dfs.core.windows.net/Temp"

#     #Write the data using Polybase
#     df.write \
#       .format("com.databricks.spark.sqldw") \
#       .option("url", url) \
#       .option("maxStrLength",4000) \
#       .option("dbtable", targetTable) \
#       .option("user", asaUserName) \
#       .option("password", asaPassword) \
#       .option("useAzureMSI", "True") \
#       .option("tempdir", tempDir) \
#       .mode(writeMode) \
#       .save()
#   except ValueError as error :
#     print("Connector write failed", error)

# COMMAND ----------

def bulkCopyDBTableToSQLDW(sourceTable, targetDatabaseName, targetTable, writeMode):
  try:
    df = spark.table(sourceTable)
      #Get the settings from config
    asaHostName = spark.conf.get("synapseHostName")
    asaUserName = spark.conf.get("synapseUserName")
    asaPassword = spark.conf.get("synapsePassword")
    asaDatabase = spark.conf.get("synapseDatabase")
    asaTempDir =  spark.conf.get("synapseTempDir")

    url = "jdbc:sqlserver://" + asaHostName + ";database=" + asaDatabase
    targetTable = targetTable.replace("[","").replace("]","")


    tempDir = "abfss://" + asaTempDir + "@" + storageAccountSynapse + ".dfs.core.windows.net/" + targetTable.replace(".","_")

      #Write the data using COPY
    df.write \
        .format("com.databricks.spark.sqldw") \
        .option("url", url) \
        .option("maxStrLength",4000) \
        .option("dbtable", targetTable) \
        .option("tempdir", tempDir) \
        .option("user", asaUserName) \
        .option("password", asaPassword) \
        .option("useAzureMSI", "true") \
        .mode(writeMode) \
        .save()
  except ValueError as error :
    print("Connector write failed", error)

# COMMAND ----------

# DBTITLE 1,Function to bulk load a Azure Synapse table from a Spark table using Azure SQL Data Warehouse connector for Azure Databricks. Use the provided connection details
def bulkCopyDBTableToSQLDWCustomConnection(sourceTable, targetDatabaseName, targetTable, writeMode, batchSize, asaHostName, asaUserName, asaPassword):
  try:
    df = spark.table(sourceTable)
    url = "jdbc:sqlserver://" + asaHostName + ";database=" + targetDatabaseName
    targetTable = targetTable.replace("[","").replace("]","")
    storageAcc = dbutils.secrets.get(scope = "datalakeconfig", key = "storageAccountDataLake")

    tempDir = "abfss://datalakestore@" + storageAcc + ".dfs.core.windows.net/Temp"

    #Write the data using Polybase
    polyCopy = spark.table(sourceTable)

    df.write \
      .format("com.databricks.spark.sqldw") \
      .option("url", url) \
      .option("maxStrLength",4000) \
      .option("dbtable", targetTable) \
      .option("user", asaUserName) \
      .option("password", asaPassword) \
      .option("useAzureMSI", "True") \
      .option("tempdir", tempDir) \
      .mode(writeMode) \
      .save()
  except ValueError as error :
    print("Connector write failed", error)

# COMMAND ----------

# DBTITLE 1,Function to execute custom SQL using an HTTP Web Request to the Azure Function
def executeCustomSQLQuery(databaseName, sqlQuery): 
  functionAppBaseURL = spark.conf.get("functionAppBaseURL")
  if "/" != functionAppBaseURL[-1]:
    functionAppBaseURL + "/"
  functionAppURL = functionAppBaseURL + "/api/ExecuteSQLQuery"

  headers={
    'x-functions-key': spark.conf.get("functionAppPowershellMasterKey")
  }

  data = {
    'serverName' : spark.conf.get("sqlHostName"),
    'databaseName' : databaseName,
    'sqlQuery' : sqlQuery
  }

  response = requests.post(url=functionAppURL, headers=headers, json=data)
  try:
    response_json = json.loads(response.text).get("Result")
    return response_json
  except:
    print(response.text)
    return response.text
