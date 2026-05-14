/* markdown llm instructions

# Data Core SQL / Database Standards

## Purpose

This document defines the initial SQL and database standards for the `data_core` schemas, including:

- schema flow and naming
- raw, staged, internal, and curated data layers
- source identifier naming using the `src_` prefix
- separation between source-supplied identifiers and internally generated identifiers

The aim is to keep source lineage clear, support repeatable ETL, and provide stable managed datasets for downstream projects, applications, reporting, and analysis.

---

# 1. Data Core Schema Flow

The `data_core` schemas are organised as a simple data maturity flow. Data moves from raw source-shaped landing tables, through light staging and internal transformation, into curated managed datasets.

Use numeric schema prefixes to make the processing order obvious and to keep schemas sorted together.

## 1.1 Schema flow

| Schema                  | Purpose                              | Typical content                                                                    |
| ----------------------- | ------------------------------------ | ---------------------------------------------------------------------------------- |
| `data_core_01_raw`      | Raw/source-shaped landing data       | Supplier field names, source structure, minimal changes                            |
| `data_core_02_stg`      | Staged and lightly standardised data | Renamed fields, typed columns, `src_` IDs, standard `geom`, CRS normalisation      |
| `data_core_03_int`      | Internal transformed model           | Normalised entities, resolved relationships, deduplication, harmonised source data |
| `data_core_04_<domain>` | Curated managed datasets             | Reusable datasets grouped by source, domain, publisher, or business domain         |

## 1.2 Recommended schemas

```text
data_core_01_raw
data_core_02_stg
data_core_03_int
data_core_04_aklc
data_core_04_linz
data_core_04_topo50
data_core_04_ref
```

Avoid using `misc` as a default schema name where possible. Prefer a clearer managed-data schema such as:

```text
data_core_04_ref
data_core_04_lookup
data_core_04_admin
data_core_04_support
```

Use `misc` only when the data genuinely has no stable domain yet.

---

## 1.3 Schema roles

### data_core_01_raw

Raw/source-shaped landing area.

This schema is used for data lake style ingestion. The aim is to preserve the supplier structure as closely as practical.

Typical characteristics:

- original supplier field names
- original source structure
- minimal transformation
- minimal interpretation
- useful for reloads, comparison, lineage, and troubleshooting

Examples:

```text
data_core_01_raw.aklc_property
data_core_01_raw.linz_title
data_core_01_raw.topo50_road
```

---

### data_core_02_stg

Staged and lightly standardised data.

This schema is used for limited ETL and source standardisation. It should not contain heavy business modelling, but it can clean up the data enough to make it safe and consistent to use downstream.

Typical characteristics:

- renamed fields
- typed columns
- standardised geometry column, usually `geom`
- standardised CRS, usually project/database CRS such as EPSG:2193 where appropriate
- source identifiers renamed with the `src_` prefix
- basic geometry validation or repair
- basic null handling
- minimal source-specific remapping

Examples:

```text
data_core_02_stg.aklc_property
data_core_02_stg.linz_title
data_core_02_stg.topo50_road
```

---

### data_core_03_int

Internal transformed model.

This schema is used for internal modelling and transformed data. This is where source-shaped datasets become the internal database model.

Typical characteristics:

- normalised entities
- resolved relationships
- deduplicated records
- harmonised attributes across sources
- internal identifiers and foreign keys
- reusable intermediate datasets
- data structured for downstream managed datasets

Examples:

```text
data_core_03_int.property
data_core_03_int.address
data_core_03_int.title
data_core_03_int.parcel
data_core_03_int.road
```

---

### `data_core_04_<domain>`

Curated managed datasets.

These schemas contain stable, documented, indexed, reusable datasets. They are the main managed data products used by projects, applications, reporting, exports, or analysis.

Group these schemas by source, publisher, domain, or business area.

Examples:

```text
data_core_04_aklc.property
data_core_04_aklc.address
data_core_04_linz.parcel
data_core_04_linz.title
data_core_04_topo50.road
data_core_04_ref.slope_class
data_core_04_ref.tla
```

---

## 1.4 Example data flow

Simple single-source flow:

```text
data_core_01_raw.aklc_property
 ↓
data_core_02_stg.aklc_property
 ↓
data_core_03_int.property
 ↓
data_core_04_aklc.property
```

Where multiple sources contribute to the same internal entity:

```text
data_core_01_raw.linz_title
data_core_01_raw.aklc_property_title
 ↓
data_core_02_stg.linz_title
data_core_02_stg.aklc_property_title
 ↓
data_core_03_int.title
 ↓
data_core_04_linz.title
```

---

# 2. Source Identifier Field Standard

Use the `src_` prefix for identifiers, keys, and source-system fields that originate from an upstream source or supplier system.

This keeps externally supplied identifiers clearly separate from internally generated database identifiers.

---

## 2.1 Core convention

| Field type                   | Naming pattern           | Example                   |
| ---------------------------- | ------------------------ | ------------------------- |
| Internal primary key         | `<entity>_id`            | `aklc_property_id`        |
| Source/supplier identifier   | `src_<entity>_id`        | `src_property_id`         |
| Source object/row identifier | `src_<source_field>`     | `src_objectid`, `src_fid` |
| Source global identifier     | `src_globalid`           | `src_globalid`            |
| Source parent identifier     | `src_parent_<entity>_id` | `src_parent_property_id`  |

---

## 2.2 Example table

```sql
CREATE TABLE data_core_02_stg.aklc_property (
 aklc_property_id serial4 NOT NULL
 , src_fid int8 NULL
 , src_objectid int8 NULL
 , src_globalid varchar(38) NULL
 , src_property_id varchar(30) NULL
 , src_parent_property_id varchar(30) NULL
 , addr_formatted varchar(100) NULL
 , addr_street_number varchar(15) NULL
 , addr_street_name varchar(50) NULL
 , addr_suburb_name varchar(40) NULL
 , addr_postcode varchar(8) NULL
 , property_description varchar(254) NULL
 , site_status varchar(8) NULL
 , site_type varchar(25) NULL
 , site_object_type varchar(20) NULL
 , address_type varchar(10) NULL
 , ac_rate_account_key varchar(35) NULL
 , rate_account_num varchar(30) NULL
 , valuation_ref varchar(23) NULL
 , titles_formatted varchar(200) NULL
 , tla_code varchar(5) NULL
 , tla_description varchar(20) NULL
 , geom public.geometry(multipolygon, 2193) NULL
 , CONSTRAINT aklc_property_pkey PRIMARY KEY (aklc_property_id)
);
```

---

## 2.3 Rationale

The `src_` prefix makes it clear that a value was supplied by an external source and should not be confused with an internally generated database key.

For example:

```sql
aklc_property_id
```

is the internal primary key created by this database, while:

```sql
src_property_id
```

is the property identifier supplied by the source system.

This distinction is important because source identifiers may not follow the same rules as internal identifiers. They may be reused, nullable, duplicated, reformatted, or changed by the supplier over time.

---

## 2.4 Recommended usage

Use `src_` for:

- upstream business identifiers
- source system row identifiers
- supplier object IDs
- supplier global IDs
- source parent/child relationship IDs
- IDs useful for lineage, reconciliation, reloads, or joins back to the source

Examples:

```sql
src_fid
src_objectid
src_globalid
src_property_id
src_parent_property_id
src_title_id
src_parcel_id
src_rate_account_id
```

---

## 2.5 Internal identifier usage

Use normal table-specific identifiers for database-created keys:

```sql
aklc_property_id
property_observation_id
building_candidate_id
source_dataset_id
```

These are controlled by the database and should be used for internal relationships, joins, foreign keys, and application logic.

---

## 2.6 Parent identifiers

If a parent identifier comes from the source system, also prefix it with `src_`.

Preferred:

```sql
src_parent_property_id
```

Avoid:

```sql
parent_property_id
```

unless it refers to an internal foreign key to another row in the same database.

---

## 2.7 Codes versus IDs

Only use `_id` when the field is genuinely an identifier.

Use `_code` for coded values:

```sql
tla_code
slope_code
status_code
```

Use `_description`, `_name`, or `_type` for human-readable values:

```sql
tla_description
site_status
address_type
site_object_type
```

---

## 2.8 Loading and aliasing

Do not use source-to-target aliases inside a `CREATE TABLE` column definition.

Invalid:

```sql
fid AS src_fid int8 NULL
```

Instead, define the target column:

```sql
src_fid int8 NULL
```

Then alias during the load step:

```sql
INSERT INTO data_core_02_stg.aklc_property (
 src_fid
 , src_objectid
 , src_globalid
 , src_property_id
)
SELECT
 fid AS src_fid
 , objectid AS src_objectid
 , globalid AS src_globalid
 , propertyid AS src_property_id
FROM
 data_core_01_raw.aklc_property;
```

---

# 3. Section Break Comment Blocks

Use a decorated block comment to mark major sections within a script:

```sql
/* section_name ==============================================
|||                                                        |||
|||   Description of section below...                      |||
|||                                                        |||
|||                                                        |||
|||                                                        |||
|||                                                        |||
|||                                                        |||
|||                                                        |||
|||                                                        |||
|||                                                        |||
|||                                                        |||
============================================================*/
--
```


# 4. Summary

Use `data_core_01_raw` for raw source-shaped landing data.

Use `data_core_02_stg` for lightly standardised staged data.

Use `data_core_03_int` for internal transformed and normalised data.

Use `data_core_04_<domain>` for curated managed datasets.

Use `src_` whenever the identifier belongs to the upstream source system.

Use internal `<entity>_id` fields for identifiers created and controlled by this database.

This creates a clear separation between source lineage, internal transformation, and curated managed data.
 */
--





/* start======================================================
|||                                                        |||
|||   Start of script/file.                                |||
|||                                                        |||
|||                                                        |||
|||                                                        |||
|||                                                        |||
|||                                                        |||
|||                                                        |||
|||                                                        |||
|||                                                        |||
|||                                                        |||
============================================================*/
--
