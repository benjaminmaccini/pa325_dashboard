# PA325 Dashboard

This is a presentation of the OASIS output for graphical analysis and policy making.

This is the sister repo to [pa325](https://github.com/benjaminmaccini/pa325)

Goals:
- Create a simple analytics dashboard so someone not on the data team can come to some sort of meaningful conclusion
as to what the behavior in the LRGV is.

TODO:
- Ratio of input nodes for given node (tot or boundary). Sankey diagram could be really good for this
- Adjust styling so that it is full screen on computer
- Salt mass balance per reach
- Inflows vs salinity
- Outflows vs salinity
- Flow mass balance
- Add weekly aggregate queries

TODO Later:
- Add annotations to salinity graphics for different levels of salinity
- Add node geolocation and point-selection filter
- Add area-of-interest map for reach selection
- Get algebraic expression working properly (and add those from the sal_bal.1v file)

## Development

### Running the project locally

You will need to install the following
- [DuckDB](https://duckdb.org)
- [HEC-DSSVue](https://www.hec.usace.army.mil/software/hec-dssvue/)
  - (on Mac this is required) [Install GCC](https://cs.millersville.edu/~gzoppetti/InstallingGccMac.html)
- [NPM](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)

Run the project with:

```bash
npm install
npm run sources
npm run dev
```

### Importing The Data

- Given a completed OASIS run, navigate to the run's directory and download the `output.dss`
file to your local computer.
- Export the file to one csv using HEC-DSSVue by selecting all the timeseries, right-clicking tabulate, then exporting to csv
- Open the csv and delete the three rows after the header as well as the first column.
- Delete the contents of the column after the date (it should be a time-value), but keep the columns header.
- Shift all the cells one cell to the left so that they are properly aligned with their respective headers
- Delete the last column of the sheet and delete it.
- Export this to a CSV file with a sensical name (`v1.1_base01212025.csv`) based on the OASIS model version and the base dataset
- Copy this to the current project directory under `sources/oasis/data`.
- Open DuckDB in the project root using `duckdb sources/oasis/oasis.duckdb`
- Get the csv import statement via `SELECT prompt FROM sniff_csv('sources/oasis/data/v1.1_base01212025.csv');` (you may need `.mode line`)
- Copy that output and create a table from the csv `CREATE TABLE oasis AS SELECT * <your pasted command here>`.
- Transform the data to the desired format for analytics using `.read tools/transform.sql`

### Data Overview

You can see the typical OASIS output via the [headers](data/headers.json) file. The general pattern is, for each reach there
are the following headers with 1xx corresponding to Reach 1, 2xx corresponding to Reach 2, etc...

- Date/Time
- x00 INFLOW: Reach start (for Reach 1 only)
- (x-1)50.x00 FLOW: Reach inflow
- x57 INFLOW: Precipitation
- x40 : Upper demand
- x50: Time-of-travel node
- x55: Evaporation
- x45: Phreatophyte demand
- x75: Lower demand
- SALTx00: Salt at reach start
- SALTx50: Salt at Time-of-travel node
- SALTINx00: Salt input to the reach (starting at node 200)
- SCONCx00: Salt concentration at the reach start (starting at node 200)
- SCONCx50: Salt concentration at the time-to-travel node
- SMB_x: The amount of salt that needs to be added or removed from the reach, the salt mass balance
- Other inputs/demands as 1xx values
- Other salt loads as SALT1xx values

Units:
- Any FLOW, INFLOW, DELIVERY, DEMAND, STORAGE is in M^3
- SCONC is mg/L
- SALT and SMB are MT
- SALT = SCONC * FLOW * 0.000001

Notes:
- DEMAND = DELIVERY = FLOW between nodes, so there is a lot of redundant information
- Series of the form `xxx.xxx`, like `100.150 FLOW` are arranged as `source_node.dest_node`.
- The date format is `%d %b %Y`

### Shape of the data

The dataset contains the following tables

1. The OASIS export (shortened for brevity -- call `DESCRIBE oasis;` for details)
|  column_name  | column_type | null | key | default | extra |
|---------------|-------------|------|-----|---------|-------|
| Date / Time   | VARCHAR     | YES  |     |         |       |
| 100 INFLOW    | DOUBLE      | YES  |     |         |       |
| 100.150 FLOW  | DOUBLE      | YES  |     |         |       |
| 120 DELIVERY  | DOUBLE      | YES  |     |         |       |
| 120 DEMAND    | DOUBLE      | YES  |     |         |       |
| 130 DELIVERY  | DOUBLE      | YES  |     |         |       |
| 130 DEMAND    | DOUBLE      | YES  |     |         |       |
| 135 INFLOW    | BIGINT      | YES  |     |         |       |
| 135.150 FLOW  | BIGINT      | YES  |     |         |       |
| 140 DELIVERY  | BIGINT      | YES  |     |         |       |
| 140 DEMAND    | BIGINT      | YES  |     |         |       |
| 145 DELIVERY  | BIGINT      | YES  |     |         |       |
| 145 DEMAND    | BIGINT      | YES  |     |         |       |
| 150 EVAP      | DOUBLE      | YES  |     |         |       |
| 150 EVAP_RATE | DOUBLE      | YES  |     |         |       |
| 150 STORAGE   | DOUBLE      | YES  |     |         |       |
| 150.120 FLOW  | DOUBLE      | YES  |     |         |       |
| 150.130 FLOW  | DOUBLE      | YES  |     |         |       |
| 150.140 FLOW  | BIGINT      | YES  |     |         |       |
| 150.145 FLOW  | BIGINT      | YES  |     |         |       |
| 150.155 FLOW  | BIGINT      | YES  |     |         |       |
| 150.200 FLOW  | DOUBLE      | YES  |     |         |       |
| 155 DELIVERY  | BIGINT      | YES  |     |         |       |
| 155 DEMAND    | BIGINT      | YES  |     |         |       |
| 157 INFLOW    | BIGINT      | YES  |     |         |       |
| 157.150 FLOW  | BIGINT      | YES  |     |         |       |
| ...           | ...         | ...  | ... |  ...    |  ...  |
| SALT500       | DOUBLE      | YES  |     |         |       |
| SALT550       | DOUBLE      | YES  |     |         |       |
| SALT600       | DOUBLE      | YES  |     |         |       |
| SALT650       | DOUBLE      | YES  |     |         |       |
| SALT700       | DOUBLE      | YES  |     |         |       |
| SALTIN200     | BIGINT      | YES  |     |         |       |
| SALTIN300     | DOUBLE      | YES  |     |         |       |
| SALTIN301     | BIGINT      | YES  |     |         |       |
| SALTIN400     | BIGINT      | YES  |     |         |       |
| SALTIN500     | DOUBLE      | YES  |     |         |       |
| SALTIN600     | DOUBLE      | YES  |     |         |       |
| SALTIN700     | DOUBLE      | YES  |     |         |       |
| SCONC150      | DOUBLE      | YES  |     |         |       |
| SCONC250      | DOUBLE      | YES  |     |         |       |
| SCONC350      | BIGINT      | YES  |     |         |       |
| SCONC450      | DOUBLE      | YES  |     |         |       |
| SCONC550      | DOUBLE      | YES  |     |         |       |
| SCONC650      | BIGINT      | YES  |     |         |       |

2. Events
| column_name  | column_type | null | key | default | extra |
|--------------|-------------|------|-----|---------|-------|
| event_date   | TIMESTAMP   | YES  |     |         |       |
| event_type   | VARCHAR     | YES  |     |         |       |
| unit         | VARCHAR     | YES  |     |         |       |
| amount       | DOUBLE      | YES  |     |         |       |
| source_node  | SMALLINT    | YES  |     |         |       |
| dest_node    | SMALLINT    | YES  |     |         |       |
| reach_number | SMALLINT    | YES  |     |         |       |

3. Nodes (TODO -- This will allow point-map filtering of the reach)
```sql
CREATE TABLE nodes (
    node SMALLINT,
    label VARCHAR,
    latitude DOUBLE,
    longitude DOUBLE,
    tags LIST -- A list of tags associated with the node, like Precipitation, Phreatophyte
);
```