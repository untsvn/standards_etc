"""markdown llm instructions

# Python Standards

## Purpose

This document defines the Python coding standards for data engineering, analysis, and automation scripts, including:

- naming conventions
- code style and structure
- notebook and script layout
- data handling patterns
- environment and configuration

---

# 1. Naming Conventions

All identifiers use lowercase `snake_case`, consistent with the database and file naming conventions.

## 1.1 Summary

| Identifier type      | Convention         | Example                 |
| -------------------- | ------------------ | ----------------------- |
| Variable             | `snake_case`       | `property_count`        |
| Function             | `snake_case`       | `load_property_data`    |
| Module / file        | `snake_case`       | `load_aklc_property.py` |
| Class                | `PascalCase`       | `PropertyLoader`        |
| Constant             | `UPPER_SNAKE_CASE` | `DEFAULT_CRS`           |
| Environment variable | `snake_case`       | `db_host`, `agol_user`  |

Classes use `PascalCase` because that is the Python standard (PEP 8).

---

## 1.2 Descriptive names

Use descriptive names. Avoid single-letter variables outside of short loop counters or well-understood conventions such as `i`, `x`, `y`.

Good:

```python
property_count = len(properties_df)
staging_records = load_staging_table("aklc_property")
```

Avoid:

```python
n = len(df)
r = load("aklc_property")
```

---

# 2. Imports

Group imports in the standard order with a blank line between each group:

1. Standard library
2. Third-party packages
3. Local / project modules

```python
import os
import json
from pathlib import Path

import pandas as pd
import geopandas as gpd
from sqlalchemy import create_engine

from utils.db import get_connection
from utils.geo import reproject_to_nztm
```

---

# 3. Script and Notebook Structure

## 3.1 Scripts

Scripts should have a clear top-level structure:

```python
# Imports
# Constants / configuration
# Functions / classes
# Main execution block
if __name__ == "__main__":
    ...
```

## 3.2 Notebooks

Notebook cells use the `# %%` cell marker for VS Code / Jupytext compatibility.

Use a named, decorated cell header for each logical section:

```python
# %% section_name ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# region ❱ section_name
# ------------------------------------------------------------------------------
#
# Cell notes here.
#
# endregion ======================================================================
```

---

# 4. Data Handling

## 4.1 DataFrames

Use `geopandas` for spatial data and `pandas` for tabular data. Prefer explicit column names over positional access.

Column names in DataFrames should match the database field names — lowercase `snake_case`.

## 4.2 CRS

Always use EPSG:2193 (NZTM2000) as the project CRS for spatial data unless otherwise required.

```python
gdf = gdf.to_crs(epsg=2193)
```

## 4.3 Database connections

Use environment variables for all connection parameters. Never hardcode credentials.

```python
import os
from sqlalchemy import create_engine

engine = create_engine(
    f"postgresql://{os.environ['db_user']}:{os.environ['db_password']}"
    f"@{os.environ['db_host']}/{os.environ['db_name']}"
)
```

---

# 5. Summary

Use `snake_case` for all identifiers except classes (`PascalCase`) and constants (`UPPER_SNAKE_CASE`).

Group imports: standard library, third-party, local.

Match DataFrame column names to database field names.

Use EPSG:2193 as the project CRS for spatial data.

Use environment variables for all credentials and connection parameters.
"""
#
# %% cell_name ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# region ❱ cell_name
# ------------------------------------------------------------------------------
#
# Cell notes in here...
#
# endregion ======================================================================
