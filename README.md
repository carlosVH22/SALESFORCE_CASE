# ☁️ AWS S3 → Snowflake ELT Pipeline

## 📌 Project Overview

Although the original technical assessment only required building a **Tableau dashboard** from three Excel worksheets, this project was expanded into a complete **cloud-based ELT pipeline** to demonstrate additional capabilities in:

- ☁️ Cloud Data Storage
- ❄️ Snowflake Data Warehousing
- 🛠️ SQL Data Transformation
- 🏗️ Data Engineering Practices
- 📊 Analytics Data Preparation

Instead of connecting Tableau directly to Excel files, the data was processed through a structured pipeline:

**Excel → CSV → AWS S3 → Snowflake → Transformation Layer → Tableau Dashboard**

This approach simulates a real-world analytics environment where raw business data is ingested, cleaned, transformed, and prepared for reporting.

---

# 🏗️ Pipeline Architecture

```text
                  📄 Excel Workbook
                         │
                         ▼
                    📁 CSV Files
                         │
                         ▼
                  ☁️ Amazon S3
              (Cloud Storage Layer)
                         │
                         ▼
              ❄️ Snowflake External Stage
                         │
                         ▼
              🗄️ RAW Tables (VARCHAR)
                         │
                         ▼
              🧹 SQL Cleaning & Transformation
                         │
                         ▼
              📊 Curated Analytics Tables
                         │
                         ▼
                 📈 Tableau Dashboard
```

---

# 🧰 Technologies Used

| Technology | Purpose |
|------------|---------|
| ☁️ Amazon S3 | Cloud storage layer for raw CSV files |
| ❄️ Snowflake | Cloud data warehouse and transformation engine |
| 🗃️ SQL | Data cleaning and business transformations |
| 📊 Tableau | Dashboard development and visualization |
| 🔐 AWS IAM Role | Secure authentication between AWS and Snowflake |

---

# 1️⃣ Snowflake Environment Setup

A dedicated database and schema were created to organize all project objects and maintain a structured analytical environment.

```sql
CREATE OR REPLACE DATABASE SALESFORCE;

USE DATABASE SALESFORCE;

CREATE OR REPLACE SCHEMA TABLEAU_SCH;

USE SCHEMA TABLEAU_SCH;
```

### Why?

Creating an isolated database and schema provides:

✅ Better organization  
✅ Separation between environments  
✅ Easier maintenance  
✅ Clear ownership of analytical objects  

---

# 2️⃣ ☁️ Connecting Snowflake with Amazon S3

The original Excel workbook contained three business entities:

- 📂 **Projects**
- 📂 **Assignments**
- 📂 **Timecards**

Each worksheet was exported as an individual CSV file and uploaded into an Amazon S3 bucket.

The S3 bucket acted as the **data landing zone**, where raw files were stored before being processed by Snowflake.

---

## 📄 CSV File Format Configuration

A custom Snowflake file format was created to correctly interpret the incoming CSV files.

```sql
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
TYPE = CSV
SKIP_HEADER = 1
FIELD_DELIMITER = ';'
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
TRIM_SPACE = TRUE
NULL_IF = ('NULL', '')
EMPTY_FIELD_AS_NULL = TRUE;
```

### ⚙️ Configuration Purpose

| Setting | Purpose |
|---------|---------|
| `SKIP_HEADER = 1` | Removes CSV header rows during ingestion |
| `FIELD_DELIMITER = ';'` | Reads semicolon-separated files |
| `FIELD_OPTIONALLY_ENCLOSED_BY` | Handles quoted text values |
| `TRIM_SPACE` | Removes unnecessary spaces |
| `NULL_IF` | Converts empty values into NULL |
| `EMPTY_FIELD_AS_NULL` | Improves data quality handling |

---

# 🔐 AWS Storage Integration

To securely connect Snowflake with Amazon S3, an external storage integration was created using an AWS IAM Role.

```sql
CREATE OR REPLACE STORAGE INTEGRATION AWS_S3_INT
TYPE = EXTERNAL_STAGE
STORAGE_PROVIDER = S3
ENABLED = TRUE
STORAGE_AWS_ROLE_ARN = 
'arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>'
STORAGE_ALLOWED_LOCATIONS = (
    's3://learn-2cloud-snowflake/'
);
```

## Why use Storage Integration?

Instead of storing AWS credentials inside Snowflake:

❌ No hardcoded access keys  
❌ No exposed credentials  
❌ No manual authentication process  

The connection is handled through:

✅ AWS IAM Role authentication  
✅ Secure cloud-to-cloud communication  
✅ Enterprise-style architecture  

---

# 📦 External Stage Creation

After configuring the Storage Integration, an External Stage was created.

The stage acts as a bridge between Amazon S3 and Snowflake tables.

```sql
CREATE OR REPLACE STAGE AWS_STAGE_TEST
STORAGE_INTEGRATION = AWS_S3_INT
URL = 's3://learn-2cloud-snowflake/loadingdata/LOADcsv/'
FILE_FORMAT = CSV_FORMAT;
```

The available files were validated using:

```sql
LIST @AWS_STAGE_TEST;
```

Expected files:

```
📄 Project.csv
📄 Assignment.csv
📄 Timecards.csv
```

---

# 3️⃣ 🗄️ RAW Data Layer

Following ELT best practices, the first Snowflake layer was designed as a **RAW ingestion layer**.

Three tables were created:

| RAW Table | Source |
|-----------|--------|
| `PROJECTS_RAW` | Project information |
| `ASSIGNMENTS_RAW` | Assignment details |
| `TIMECARDS_RAW` | Time tracking records |

---

## Why store data as VARCHAR?

All incoming columns were intentionally created as `VARCHAR`.

Example:

```sql
CREATE OR REPLACE TABLE PROJECTS_RAW (

    ID VARCHAR,
    NAME VARCHAR,
    SUBMITTED_HOURS VARCHAR,
    FORECASTED_HOURS VARCHAR,
    ACTUAL_REVENUE VARCHAR,
    FORECASTED_REVENUE VARCHAR

);
```

### Advantages:

✅ Preserves original source values  
✅ Prevents ingestion failures due to unexpected formats  
✅ Allows controlled transformations later  
✅ Maintains historical traceability  

This follows a common enterprise ELT pattern:

```
Raw Data First → Transform Later
```

---

# 4️⃣ 📥 Loading Data from Amazon S3

Once the RAW tables were created, the CSV files were loaded from S3 using Snowflake's `COPY INTO` command.

Example:

```sql
COPY INTO PROJECTS_RAW
FROM @AWS_STAGE_TEST/Project.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)
ON_ERROR = 'CONTINUE';
```

The same ingestion process was executed for:

```text
📌 ASSIGNMENTS_RAW
📌 TIMECARDS_RAW
```

---

## Error Handling Strategy

The parameter:

```sql
ON_ERROR = 'CONTINUE'
```

was implemented to avoid stopping the complete ingestion process due to isolated data quality issues.

Benefits:

✅ Allows successful records to load  
✅ Prevents pipeline interruption  
✅ Enables later investigation of problematic rows  

---

# ✅ Result

At this stage, the pipeline successfully achieved:

✔️ Cloud file storage in AWS S3  
✔️ Secure Snowflake-S3 integration  
✔️ Automated CSV ingestion  
✔️ RAW data preservation  
✔️ Foundation for SQL transformations  

The next step is the **Transformation Layer**, where raw data is cleaned, standardized, converted into analytical formats, and prepared for Tableau consumption.

---
# 🛠️ Data Transformation & Cleaning

After successfully loading the source files into the **RAW layer**, the next step was to transform the data into a clean and analytics-ready format.

Rather than modifying the original CSV files, all business rules and data quality validations were implemented directly in **Snowflake**, following an **ELT (Extract, Load, Transform)** architecture.

This approach preserves the original source data while creating a curated layer optimized for reporting and dashboard development.

---

## 🎯 Objectives

The transformation process focused on:

- 🧹 Cleaning inconsistent values
- 🔄 Converting text into appropriate data types
- 💰 Standardizing currency values
- 📅 Parsing dates into Snowflake `DATE` format
- ✂️ Removing unnecessary spaces
- 🏷️ Renaming columns using business-friendly names
- 🚫 Removing invalid records
- 📊 Preparing the data for Tableau

---

# 📂 Projects Transformation

The `PROJECTS_RAW` table was transformed into the final `PROJECTS` table.

### Transformations applied

| Transformation | Purpose |
|---------------|---------|
| `TRIM()` | Removes leading and trailing spaces from project names. |
| `TRY_TO_DOUBLE()` | Converts numeric values stored as text into numeric data types. |
| `REPLACE()` | Standardizes decimal separators from European format to standard decimal notation. |
| Currency cleaning | Removes `$` symbols and thousand separators before conversion. |
| Column aliases | Renames technical column names into business-friendly fields. |
| Data validation | Removes records without a valid Project ID. |

Example:

```sql
TRY_TO_DOUBLE(
    REPLACE(
        REPLACE(
            REPLACE(ACTUAL_REVENUE,'$',''),
            '.',''
        ),
        ',','.'
    )
) AS ACTUAL_REVENUE
```

### Example Conversion

| Original Value | Transformed Value |
|---------------|------------------|
| `$1.245.430,50` | `1245430.50` |

This allows Snowflake to perform aggregations, calculations and KPI generation without additional preprocessing.

---

# 📂 Assignments Transformation

The same transformation strategy was applied to the `ASSIGNMENTS_RAW` table.

Additional transformations included:

- 💵 Bill Rate standardization
- 📈 Revenue conversion
- ⏱️ Submitted Hours conversion
- 📊 Forecasted Hours conversion
- 🏷️ Assignment Status normalization
- ✂️ Removal of unnecessary spaces

Example:

```sql
TRIM(ASGN_STATUS) AS ASSIGNMENT_STATUS
```

and

```sql
TRY_TO_DOUBLE(
    REPLACE(
        REPLACE(
            REPLACE(BILL_RATE,'$',''),
            '.',''
        ),
        ',','.'
    )
) AS BILL_RATE
```

---

# 📂 Timecards Transformation

The **Timecards** dataset required additional processing because the original file stored dates using **Spanish month abbreviations**, which Snowflake cannot parse directly.

Example source values:

```text
09/feb/2025
15/abr/2025
20/dic/2025
```

Before converting these values into the `DATE` data type, every month abbreviation was translated into its English equivalent.

| Spanish | English |
|----------|----------|
| ene | jan |
| feb | feb |
| mar | mar |
| abr | apr |
| may | may |
| jun | jun |
| jul | jul |
| ago | aug |
| sep | sep |
| oct | oct |
| nov | nov |
| dic | dec |

Example:

```sql
TRY_TO_DATE(

    REPLACE(
        LOWER(WEEK_START),
        'dic',
        'dec'
    ),

'DD/MON/YYYY')
```

This process guarantees that all dates are stored as native Snowflake `DATE` values, enabling chronological analysis and time intelligence within Tableau.

---

## 📌 Data Quality Rules

During the transformation process, several validation rules were implemented to improve data quality.

### ✅ Text Cleaning

- Remove leading spaces
- Remove trailing spaces

Using:

```sql
TRIM(column_name)
```

---

### ✅ Numeric Conversion

Numeric fields stored as text were safely converted using:

```sql
TRY_TO_DOUBLE()
```

instead of `TO_DOUBLE()`.

Using `TRY_TO_DOUBLE()` prevents the transformation from failing when invalid values are encountered, returning `NULL` instead of raising an exception.

---

### ✅ Currency Standardization

Currency values contained:

- Dollar symbols (`$`)
- Thousand separators (`.`)
- Decimal commas (`,`)

Example:

```text
$1.234.567,89
```

became

```text
1234567.89
```

making the values suitable for analytical calculations.

---

### ✅ Record Validation

Only records containing a valid primary identifier were loaded into the curated layer.

```sql
WHERE ID IS NOT NULL
```

This prevents incomplete or empty records from affecting downstream analyses.

---

# ✅ Curated Layer

After completing all transformations, three production-ready tables were created:

- 📁 `PROJECTS`
- 📁 `ASSIGNMENTS`
- 📁 `TIMECARDS`

These tables contain:

- ✔️ Correct data types
- ✔️ Standardized values
- ✔️ Clean text fields
- ✔️ Parsed dates
- ✔️ Validated records
- ✔️ Business-friendly column names

The curated layer serves as the trusted data source for Tableau, enabling reliable KPI calculations, interactive dashboards, and analytical reporting while preserving the original RAW data for traceability and future reprocessing.

## 📊 Project Performance Command Center

The **Project Performance Command Center** is an interactive dashboard designed to provide a consolidated view of project profitability, resource allocation, revenue performance, and operational efficiency.

The dashboard is connected directly to **Snowflake**, allowing the visualizations to work with the project data stored in the cloud data warehouse without requiring manual extracts or intermediate files.

---

### 🖼️ Dashboard Preview

> Add the dashboard image to the repository and replace the path below if necessary.

```markdown
![Project Performance Command Center](images/project_performance_dashboard.png)
```

---

## 🎯 Dashboard Objectives

The dashboard was created to help stakeholders quickly answer questions such as:

- Are projects generating the expected revenue?
- Which projects are underperforming?
- Which projects require immediate attention?
- Are teams investing more hours than originally planned?
- Which projects generate the most revenue per hour?
- How has the submitted workload evolved over time?
- Is project performance being driven by additional hours, higher revenue, or both?

Instead of evaluating revenue and effort independently, the dashboard combines both perspectives to provide a more complete view of project performance.

---

## 🔎 Interactive Filters

The dashboard includes filters that allow users to explore the portfolio from different perspectives:

- **Project ID:** isolates one or multiple projects.
- **Project Status:** filters projects according to their profitability classification.
- **Week Day Start:** restricts the analysis to a selected project or reporting period.

All dashboard components respond to these filters, enabling users to move from a portfolio-level overview to a more detailed project-level analysis.

---

## 🚦 Project Status Classification

A calculated field was created to classify each project according to its actual revenue compared with its forecasted revenue.

```text
IF [Actual Revenue] >= [Forecasted Revenue] THEN "Good"

ELSEIF [Actual Revenue] >= [Forecasted Revenue] * 0.8 THEN "At Risk"

ELSE "Bad"

END
```

The resulting categories are:

- 🟢 **Good:** Actual revenue is equal to or greater than forecasted revenue.
- 🟡 **At Risk:** Actual revenue reaches at least 80% of the forecast but remains below the original target.
- 🔴 **Bad:** Actual revenue is below 80% of the forecasted amount.

This classification transforms the revenue comparison into a simple and actionable indicator. Stakeholders can immediately distinguish projects that are meeting expectations from those that may require intervention.

The status distribution is also summarized visually, making it easier to understand the overall health of the project portfolio.

---

## 📌 Key Performance Indicators

The top section of the dashboard contains KPI cards that summarize the most relevant portfolio metrics:

- **Total Projects**
- **Total Assignments**
- **Total Revenue**
- **Submitted Hours**

Each KPI card provides a high-level view of the current portfolio and acts as an entry point for deeper analysis.

Conditional indicators are used to communicate performance direction. Positive changes are represented in green, while negative changes are displayed in red. This allows users to identify improvements or unfavorable deviations without having to inspect every individual value.

---

## 💰 Actual vs. Forecasted Revenue

The **Actual vs. Forecasted Revenue** chart compares the revenue generated by each project against its expected revenue.

Actual and forecasted values are presented together, making it possible to identify:

- Projects that exceeded their revenue target.
- Projects that performed close to expectations.
- Projects with a significant gap between actual and forecasted revenue.
- Projects where the forecast may have been overly optimistic.

Displaying both values in the same view provides more context than analyzing actual revenue alone. A project with high revenue may still be considered underperforming when its original forecast was substantially higher.

---

## 📉 Revenue Variance

The **Difference vs. Forecast** visualization shows the absolute revenue variance for every project.

```text
Revenue Variance = Actual Revenue - Forecasted Revenue
```

The chart uses conditional coloring to distinguish the direction of the variance:

- 🟢 **Green:** Actual revenue exceeded the forecast.
- 🔴 **Red:** Actual revenue remained below the forecast.

The diverging layout makes large positive and negative deviations easy to detect. Projects with the greatest revenue shortfalls stand out immediately, helping stakeholders prioritize investigation and corrective actions.

---

## 🧭 Revenue and Hours Performance Matrix

A performance matrix was created to compare projects using two dimensions:

- **Revenue variance percentage:** the proportion of actual revenue relative to forecasted revenue.
- **Hours variance percentage:** the proportion of submitted hours relative to planned hours.

This visualization provides a more complete interpretation of project performance because revenue results are evaluated alongside the effort required to produce them.

The matrix is divided into four general performance scenarios:

| Revenue performance | Hours performance | Interpretation |
|---|---|---|
| Above forecast | Below planned hours | Highly efficient project |
| Above forecast | Above planned hours | Strong revenue, but additional effort was required |
| Below forecast | Below planned hours | Lower performance with limited resource usage |
| Below forecast | Above planned hours | Potentially inefficient or unprofitable project |

Reference lines at zero separate positive and negative variances, while each project is represented individually within the matrix.

This makes it possible to identify projects that may appear successful from a revenue perspective but required substantially more hours than expected. It also highlights projects that achieved favorable revenue results while consuming fewer resources.

---

## ⏱️ Project Hours Distribution

The **Projects by Hour** treemap shows how submitted hours are distributed across the project portfolio.

Each rectangle represents a project, and its size is determined by the number of submitted hours. Larger blocks indicate projects that consumed a greater proportion of the team’s available capacity.

This view helps identify:

- Projects with the highest resource consumption.
- Concentration of working hours across the portfolio.
- Projects that may require workload or staffing reviews.
- Potential dependencies on a small number of high-effort projects.

The treemap format provides a compact view of portfolio composition and makes relative workload differences easy to understand.

---

## ⚡ Revenue per Hour

The **Revenue per Hour** table evaluates the revenue generated for each submitted hour.

```text
Revenue per Hour = Actual Revenue / Submitted Hours
```

Projects are ranked by this metric, helping identify which initiatives are converting effort into revenue most effectively.

A high value indicates that the project generates more revenue for every hour invested. A low value may indicate:

- Lower margins.
- Excessive resource consumption.
- Delivery inefficiencies.
- Underestimated project complexity.
- Revenue performance below expectations.

This metric complements the total revenue view. A project may generate a large amount of revenue but still be less efficient when the total number of hours invested is considered.

---

## 📈 Submitted Hours by Week

The timeline at the bottom of the dashboard displays the evolution of submitted hours over time.

This visualization helps users understand:

- Changes in workload across reporting periods.
- Weeks with unusually high activity.
- Growth or decline in resource utilization.
- Potential delivery peaks.
- Periods that may require additional staffing or capacity planning.

The area chart emphasizes both the weekly values and the overall workload trend, providing an operational perspective that complements the financial analysis.

---

## 🎨 Visual Design and Conditional Formatting

The dashboard follows a consistent visual language intended to reduce interpretation time:

- 🟢 **Green** represents favorable performance or positive revenue variance.
- 🟡 **Yellow** identifies projects that are close to falling below expectations.
- 🔴 **Red** highlights unfavorable performance, revenue shortfalls, or projects requiring attention.
- 🔵 **Blue and neutral tones** are used for general metrics and comparisons.
- Distinct colors in the treemap help separate projects and improve readability.

Conditional colors are particularly important in the revenue variance and project-status visualizations, where users need to distinguish positive and negative outcomes quickly.

The dashboard also combines several visualization types—KPI cards, bar charts, diverging bars, scatter plots, treemaps, ranked tables, and time-series charts—to present each metric using the most appropriate visual format.

---

## 💡 Main Analytical Value

The dashboard goes beyond reporting total revenue. It combines financial performance with operational effort to identify projects that are:

- Profitable and efficient.
- Profitable but resource-intensive.
- Close to missing their financial targets.
- Generating insufficient revenue.
- Consuming more hours than planned.
- Producing a low return for every hour invested.

This approach supports more informed decisions related to project prioritization, resource allocation, forecasting, pricing, and portfolio management.

---

## 🔌 Data Connection and Publishing Limitations

The dashboard uses a **direct connection to Snowflake**. This allows the workbook to query the source data directly, but it also introduces deployment limitations.

The dashboard could not be published as a fully functional public or hosted version because:

- The visualizations depend on access to the Snowflake environment.
- Database credentials and connection details cannot be exposed publicly.
- External users would require the appropriate Snowflake permissions.
- The free version used for the project does not provide all the capabilities required to host and maintain the direct database connection.
- Publishing the workbook without its active connection would prevent the dashboard from refreshing or retrieving the underlying data.

For these reasons, the repository includes a static preview of the dashboard rather than an externally accessible live version.

---

## 🛠️ Technologies Used

- **Snowflake** — cloud data warehouse and primary data source.
- **Tableau** — dashboard development, calculated fields, interactive filters, and visual analytics.
- **SQL** — data retrieval and preparation.
- **Calculated fields** — project-status classification, revenue variance, variance percentages, and efficiency metrics.
