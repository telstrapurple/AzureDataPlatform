# Modern Data Warehouse Notebooks

This folder contains the Databricks notebooks required for cleansing data in the Bronze layer and ingesting into a Silver layer

## Structure

```
|-- Cleanse Table To Lake.ipynb         <-- Entry Script to initiate cleansing

|-- Clean.ipynb                         <-- Script collating all cleaning functions

|-- Cleanse by Data Type                <-- Cleaning methods specific to certain data types
|--|-- Datetime.ipynb
|--|-- Numeric.ipynb
|--|-- String.ipynb

|-- Util
|--|-- Config.ipynb                     <-- Script to collect Storage Account Secrets from Key Vault
|--|-- Util Functions.ipynb             <-- General functions used in all cleansing methods
```

## Usage

### Calling Scripts

The script is called by Azure Data Factory, with an ADP task for each table that is being cleansed

### Configuration Parameter

`Cleanse Table To Lake.ipynb` takes a JSON String with the following schema as input parameter:

```json
{
  "sourceFilePath": "Parth/To/File Relative to the Datalake Container",
  "sourceFileType": "<'parquet' or 'delta' or 'csv'>",
  "targetFilePath": "Parth/To/File Relative to the Datalake Container",
  "cleanseObject": [
    {
      "type": "Clean or Validate",
      "task": "functionName",
      "inputs": {
        "columns": ["list", "of", "column", "names"],
        "error_action": "<'continue_and_null_value' or 'continue_and_drop_row' or 'continue_and_replace_value' or 'stop'>",
        "e.t.c": 0
      }
    }
  ]
}
```

The cleanseObject Parameter is a list of JSON Objects used to define what cleansing functions will be executed on the table. `type` indicates whether the function is a cleaning or validation method, `task` is the name of the method to be run, and `inputs` is a JSON Object of function parameters. The following is a list of available functions:

| Task                    | Description                                                                                   | Type  | Inputs                                                                              | Data Type |
| ----------------------- | --------------------------------------------------------------------------------------------- | ----- | ----------------------------------------------------------------------------------- | --------- |
| cln_title_case          | Converts all strings to Proper Case for each column listed.                                   | Clean | columns: list, error_action: str                                                    | String    |
| cln_lower_case          | Converts all strings to lower case for each column listed.                                    | Clean | columns: list, error_action: str                                                    | String    |
| cln_upper_case          | Converts all strings to UPPER CASE for each column listed.                                    | Clean | columns: list, error_action: str                                                    | String    |
| cln_regex_replace       | Replaces values matching a regex expression with the specified value for each column listed.  | Clean | columns: list, regex_exp: str, replace_string: str, error_action: str               | String    |
| cln_fuzzy_match_replace | Replaces values that are similar to the first string in a common list for each column listed. | Clean | columns: list, common_strings: list, similarity_threshold: float, error_action: str | String    |
| clnMinMaxNormalise      | Applies Min Max Normalisation to all values in a column for each column listed.               | Clean | columns: list, ErrorAction: str                                                     | Numeric   |

### Adding More Functions

If a cleansing function is datatype specific:

1. Write a method in the relevant notebook in `Cleanse by Data Type`
2. Add a call to the method in the Clean or Validate Class in Clean.ipynb or Validate.ipynb respectively

Alternatively add the method to the Clean or Validate Class in Clean.ipynb or Validate.ipynb respectively
