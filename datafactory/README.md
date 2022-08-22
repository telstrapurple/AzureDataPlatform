# Azure Data Factory

## Naming conventions

### Data Sets

Data set object names will be prefixed with `Generic_` and the name of the data set should contain the name of data source type, including an indication of whether the data set is using the Self-Hosted integration runtime or the Azure-Hosted runtime.

#### Folders

For data sets, all folder names will be indicative of the type of data source being connected to.

### Pipelines

Pipeline names should be prefixed with `Pipe_` and the name of the pipeline should be descriptive but concise.

#### Folders

All pipelines related to a specific type of source will be grouped together in the same folder, e.g. `Database Load` for database pipelines which perform loads from database sources.

### Connections

Connections will follow the naming conventions defined for the underlying Azure service (where applicable), replacing all instances of dashes `-` with an underscore `_`. In cases where connections are made to specific databases, e.g. SQL Server connections, the database name will be appended to the name of the connector, e.g.

TP_SYD_DEV_ADP_SQL_001 Test_DW

### Triggers

All trigger names will match the names of the schedules created in the ADS web application, e.g. `Once per day`, `Once every 6 hours` etc

Once the triggers have been created, the `Pipe_Master_Generic_Schedule_Load` pipeline located in the `Master Pipelines` folder should be attached to all of the triggers and scheduled to run on the required date and frequency.

If specific data sources need to be extracted on an ad-hoc basis, run the applicable `Pipe_Generic_<Source Type>_Load_Parallel` pipeline located in the data source type folder.

For example, for database loads, manually trigger the `Pipe_Generic_Database_Load_Parallel` pipeline (for all parallel tasks) or `Pipe_Generic_Database_Load_Sequential` pipeline (for all sequential tasks) and specify the following parameters from the web configuration:

- `System` - The name of the system to execute
- `TaskType` - The name of the task type to execute, e.g. `On Prem SQL to Lake`
- `Schedule` - The name of the schedule to run against

The execution of the pipelines can then be monitored through the Azure Data Factory Web UI under `Monitor > Pipeline Runs`. Note that no automated error notifications will be sent out if these pipelines are executed manually - only execution of the `Pipe_Master_Generic_Schedule_Load` pipeline will result in these notifications being processed.

### Tasks

All task names will be prefixed by the acronyms below based on the task type being executed.

| Prefix | Task Type            |
| ------ | -------------------- |
| APP    | Append variable      |
| AZF    | Azure function       |
| CD     | Copy Data            |
| DEL    | Delete task          |
| DBN    | Databricks task      |
| EP     | Execute pipeline     |
| FLT    | Filter               |
| FOR    | Foreach              |
| GM     | Get metadata         |
| IF     | If condition         |
| LKP    | Lookup               |
| SP     | SQL Stored Procedure |
| SV     | Set variable         |
| UNT    | Until                |
| VAL    | Validation           |
| WEB    | Web                  |
| WHK    | Webhook              |
| WT     | Wait                 |

| Name                               | Unique Name                                                                                                       | Validation Checks                                                                                                                                                                                                                                                                                                                                                                         |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Data Factory                       | Unique across Microsoft Azure. Names are case-insensitive, that is, MyDF and mydf refer to the same data factory. | - Each data factory is tied to exactly one Azure subscription. <br> - Object names must start with a letter or a number, and can contain only letters, numbers, and the dash (-) character. <br> - Every dash (-) character must be immediately preceded and followed by a letter or a number. Consecutive dashes are not permitted in container names. Name can be 3-63 characters long. |
| Linked Services/Datasets/Pipelines | Unique across Microsoft Azure. Names are case-insensitive, that is, MyDF and mydf refer to the same data factory. | - Object names must start with a letter, number, or an underscore (\_). <br> - Following characters are not allowed: “.”, “+”, “?”, “/”, “<”, ”>”,”\*”,”%”,”&”,”:”,”\” <br> - Dashes (""-"") are not allowed in the names of linked services and of datasets only.                                                                                                                        |

### Additional Information

Source: https://docs.microsoft.com/en-us/azure/data-factory/naming-rules

## Sample Oracle Database

### Virtual Machine with Oracle installed

If you want this data source, you will need to create you own Oracle Database server by following the instructions [here](https://docs.oracle.com/en/database/oracle/oracle-database/18/xeinw/).

### Sample Oracle Database

The database used for the sample is Oracle Express 18 EX. Download it [here](https://www.oracle.com/database/technologies/xe-downloads.html).

- Note: the same password is used for SYS, SYSTEM and PDBADMIN accounts
- SYS has higher privileges than SYSTEM

### Sample Oracle Multitenant Architecture

- Oracle databases come now as multitenant databases, which includes one Container Database (CDB) and one or more pluggable databases (PDB). There are views available to see the databases within a container (https://docs.oracle.com/database/121/ADMIN/cdb_mon.htm#ADMIN13933)
- Note: sample databases must be deployed in a pluggable database, not a container database

### Sample Oracle Schemas

Sample Oracle Schemas can be found [here](https://docs.oracle.com/en/database/oracle/oracle-database/18/comsc/index.html).

### Clients

The two clients used to interact with the sample database are SQL Developer and SQL Plus.

#### SQL Developer Login

- to log into the Container Database, enter EX into the SID
- to log into the pluggable databases, enter the pluggable database name as the Service

#### SQL Plus

- SQL Plus comes with the installation of the Oracle database, so will already be on the machine that Oracle is installed on
- Access SQL Plus from the windows command prompt by typing 'sqlplus'
- Log into SQL Plus with username: SYS AS SYSDBA
