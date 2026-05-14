# Database Conventions

## Scope

These conventions apply across all data storage formats, including:

- PostgreSQL databases
- Flat files on disk (Shapefile, KML, GeoJSON)
- ArcGIS Online (AGOL)

---

## Object and Table Naming

Object names and table names should be **descriptive**.

---

## Role and User Naming

In Postgres, a user and a role are the same object — the object is a **role**.

### Privilege Controlling Roles

These are `NOLOGIN INHERIT` roles used to assign privileges to individual entities. They are the object that privileges are granted to, not connected with directly.

- Prefixed with `role_`

### Admin Users

`LOGIN NOINHERIT` roles for individual admin users connecting to the database.

- Prefixed with `admin_`

### Application Users

`LOGIN` roles for applications connecting to the database.

- Prefixed with `app_`

### Normal User Accounts

`LOGIN` roles for individual human users (editors, viewers, etc.).

- Named as `firstname_lastname`

> **Open question:** What admin-type tasks will be allowed for normal users vs. restricted to admin users?
>
> - Create table?
> - Drop table?

### Naming Summary

| Role Type             | Prefix   | Example           |
| --------------------- | -------- | ----------------- |
| Privilege controlling | `role_`  | `role_db_admin`   |
| Admin users           | `admin_` | `admin_sam_brown` |
| Application users     | `app_`   | `app_geoserver`   |
| Normal users          | _(none)_ | `sam_brown`       |

### Example SQL

```sql
-- Privilege controlling role with full database privileges
CREATE ROLE role_db_admin NOSUPERUSER NOLOGIN;
GRANT ALL PRIVILEGES ON DATABASE geodata TO role_db_admin;

CREATE ROLE role_editors NOSUPERUSER NOLOGIN;

-- Admin user login roles assigned to the privilege controlling role
CREATE ROLE admin_sam_brown LOGIN NOINHERIT PASSWORD '*****';
GRANT role_db_admin TO admin_sam_brown;

CREATE ROLE admin_josh_jones LOGIN NOINHERIT PASSWORD '*****';
GRANT role_db_admin TO admin_josh_jones;

-- Application login roles
CREATE ROLE app_inference LOGIN;
CREATE ROLE app_carboncommit LOGIN;
CREATE ROLE app_geoserver LOGIN;

-- Normal user login roles
CREATE ROLE sam_brown LOGIN PASSWORD '*****';
CREATE ROLE gordon_morris LOGIN PASSWORD '*****';
CREATE ROLE maia_waipara LOGIN PASSWORD '*****';
CREATE ROLE dan_bull LOGIN PASSWORD '*****';
CREATE ROLE andrew_hansford LOGIN PASSWORD '*****';
```

---

## Table Naming

Tables should use the **singular** form.

While it feels natural to call it a `surveys` table, each row represents a single survey. Using singular names also makes the foreign key pattern of `tablename_id` more intuitive.

See: [Stack Overflow — Table naming dilemma: singular vs. plural](https://stackoverflow.com/questions/338156/table-naming-dilemma-singular-vs-plural-names)

---

## Object Naming

### No Reserved Words

Do not name any object using a SQL reserved word. Doing so forces the use of brackets or quotes throughout all downstream code and tooling.

References:

- [Wikipedia — List of SQL reserved words](https://en.wikipedia.org/wiki/List_of_SQL_reserved_words)
- [Stack Overflow — How to use a reserved word as a table name](https://stackoverflow.com/questions/54479920/how-to-use-a-reserved-word-in-sql-as-a-table-name) _(for reference only — we do not do this)_

### Lowercase Snake_case for All Identifiers

Use lowercase `snake_case` for all identifiers that humans will copy/paste across systems. This applies to:

- Database objects (schemas, tables, views, columns, indexes, constraints)
- File and folder names
- Service and layer names
- API paths and JSON keys
- Config keys and environment variables
- Scripts, notebooks, and repo artifact names

All identifiers must begin with a letter — not a number or underscore.

**Why**

| Reason                             | Detail                                                                                               |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Works everywhere without surprises | Lowercase + underscores behaves consistently across SQL, code, CLIs, URLs, and filesystems — no quoting or escaping needed |
| Copy/paste ergonomics              | Double-click selects the entire `snake_case` token in most tools; with kebab-case, double-click often selects only one word around the hyphen |
| Less ambiguity on the command line | `-` is associated with flags and option parsing; `_` is rarely overloaded that way                   |
| Readable and searchable            | Word boundaries are clear without relying on capitalisation, reducing inconsistent variants          |

**Good examples**

```
building_alignment_workflow
tmp_build_ambiguous_remaining_prev
tile_status
attachments_size_mb
prop_flood_submission_v25
```

**Avoid**

| Identifier                    | Reason to avoid                                  |
| ----------------------------- | ------------------------------------------------ |
| `BuildingAlignmentWorkflow`   | Mixed case → quoting/case issues in some systems |
| `building-alignment-workflow` | Hyphen selection issues + CLI ambiguity          |
| `Building Alignment Workflow` | Spaces → escaping/quoting everywhere             |
| `buildingAlignmentWorkflow`   | Harder to scan; inconsistent across teams        |

### Display Names vs. Identifiers

Where a system supports it, use human-friendly display labels separately from the underlying identifier:

- **Identifier:** `flooded_property_locations`
- **Display label:** Flooded Property Locations

### Environment Variables

Use lowercase `snake_case`, consistent with all other identifiers in this document:

- `agol_url`, `agol_user`

> **Note:** Uppercase `AGOL_URL` is a widespread convention in shell and CI environments. Either form is widely understood — the key is consistency within a project.

---

## Views and Materialized Views

Do **not** use a prefix or suffix to indicate whether an object is a table, view, or materialized view.

Common patterns to avoid:

| Pattern                     | Example                    |
| --------------------------- | -------------------------- |
| `<name>_v` / `v_<name>`     | `survey_v`, `v_survey`     |
| `<name>_vw` / `vw_<name>`   | `survey_vw`, `vw_survey`   |
| `<name>_mv` / `mv_<name>`   | `survey_mv`, `mv_survey`   |
| `<name>_tbl` / `tbl_<name>` | `survey_tbl`, `tbl_survey` |

### Rationale

Name the **data**, not the implementation. The benefits of this approach:

- Shorter, cleaner names
- No need to refactor downstream code if an object changes from a table to a view or materialized view
- Most tools are agnostic to the underlying implementation type

---

## Primary Keys

> **Open question:** Use `id` for primary key and `tablename_id` for foreign keys, or `tablename_id` consistently throughout?
>
> Leaning toward `id` as the primary key column name and `tablename_id` for foreign keys, but there are good arguments both ways.|
>
> See: [Stack Overflow — Naming of ID columns in database tables](https://stackoverflow.com/questions/208580/naming-of-id-columns-in-database-tables)
>
>

Decision made to go with `tablename_id` for both pk and fk.

### Primary Key Column Creation

Use `GENERATED BY DEFAULT AS IDENTITY` (PostgreSQL 10+):

```sql
CREATE TABLE survey (
  survey_id integer GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  ...
  geom geometry(MultiPolygon, 2193)
);
```

This is the SQL 2011 standard and the modern replacement for `serial`. The sequence is bound to the column and drops with it automatically, making schemas self-contained for cloning and migration.

**Why not the alternatives:**

| Option | Reason to avoid |
|---|---|
| `serial` | Sequence lives outside table metadata; non-standard; older idiom |
| `integer` (plain) | No auto-increment; requires manual sequence management |

`GENERATED ALWAYS AS IDENTITY` is stricter — it blocks inserting your own value unless you use `OVERRIDING SYSTEM VALUE`. `BY DEFAULT` is preferred as it allows explicit inserts when needed (e.g. bulk loads, migrations).

---

## Foreign Keys

Foreign key columns should be named `<related_table_name>_id`.

**Example:**

```sql
-- In the landcover table, a foreign key referencing the survey table:
survey_id
```

---

## Geometry Columns

The geometry column should be named `geom` and placed as the **last column** in the table.

If a table has more than one geometry column, use descriptive names that distinguish them (e.g. `geom_point`, `geom_boundary`).

---

## Index Naming

| Index type | Pattern | Example |
|---|---|---|
| Standard index | `idx_<tablename>_<fieldname>` | `idx_survey_status` |
| Spatial index | `sidx_<tablename>_geom` | `sidx_survey_geom` |

If a table has a non-`geom` geometry column, substitute the actual column name in the spatial index (e.g. `sidx_survey_geom_boundary`).

**Example SQL**

```sql
-- Standard index
CREATE INDEX idx_survey_status
  ON survey (status);

-- Spatial index
CREATE INDEX sidx_survey_geom
  ON survey
  USING gist (geom);
```