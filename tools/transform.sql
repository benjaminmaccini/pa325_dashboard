-- This file transforms the oasis table, directly as uploaded, into an events table for analytics
CREATE TABLE events AS
WITH RECURSIVE
pivoted AS (
    UNPIVOT oasis ON COLUMNS( * EXCLUDE ("Date / Time")) INTO NAME names VALUE amount
),
-- Parse flow columns
flow_events AS (
  SELECT
    strptime("Date / Time", '%d %b %Y') as event_date,
    'FLOW' as event_type,
    'M3' as unit,
    CAST(pivoted.amount as DOUBLE) as amount,
    CAST(REGEXP_EXTRACT(pivoted.names, '(\d+)\.(\d+)', ['source', 'dest']).source as SMALLINT) as source_node,
    CAST(REGEXP_EXTRACT(pivoted.names, '(\d+)\.(\d+)', ['source', 'dest']).dest as SMALLINT) as dest_node,
    LEAST(source_node // 100, dest_node // 100) as reach_number
  FROM pivoted
  WHERE names LIKE '% FLOW'
),
-- Parse INFLOW columns
inflow_events AS (
  SELECT
    strptime("Date / Time", '%d %b %Y') as event_date,
    'FLOW' as event_type,
    'M3' as unit,
    CAST(pivoted.amount as DOUBLE) as amount,
    CAST(REGEXP_EXTRACT(pivoted.names, '(\d+)', ['node']).node as SMALLINT) as source_node,
    NULL as dest_node,
    CAST(REGEXP_EXTRACT(pivoted.names, '^(\d)', ['node']).node as SMALLINT) as reach_number,
  FROM pivoted
  WHERE names LIKE '% INFLOW'
),
-- Parse SCONC columns
sconc_events AS (
  SELECT
    strptime("Date / Time", '%d %b %Y') as event_date,
    'SALINITY' as event_type,
    'MG/L' as unit,
    CAST(pivoted.amount as DOUBLE) as amount,
    CAST(REGEXP_EXTRACT(pivoted.names, 'SCONC(\d+)', ['node']).node as SMALLINT) as source_node,
    NULL as dest_node,
    CAST(REGEXP_EXTRACT(pivoted.names, 'SCONC(\d)', ['node']).node as SMALLINT) as reach_number,
  FROM pivoted
  WHERE names LIKE 'SCONC%'
),
-- Parse SALT columns
salt_events AS (
  SELECT
    strptime("Date / Time", '%d %b %Y') as event_date,
    'SALT' as event_type,
    'MT' as unit,
    CAST(pivoted.amount as DOUBLE) as amount,
    CAST(REGEXP_EXTRACT(pivoted.names, 'SALT(\d+)', ['node']).node as SMALLINT) as source_node,
    NULL as dest_node,
    CAST(REGEXP_EXTRACT(pivoted.names, 'SALT(\d)', ['node']).node as SMALLINT) as reach_number,
  FROM pivoted
  WHERE names LIKE 'SALT%' AND names NOT LIKE 'SALTIN%'
),
-- Parse SMB columns
smb_events AS (
  SELECT
    strptime("Date / Time", '%d %b %Y') as event_date,
    'SALT_MASS_BALANCE' as event_type,
    'MT' as unit,
    CAST(pivoted.amount as DOUBLE) as amount,
    CAST(REGEXP_EXTRACT(pivoted.names, 'SMB_(\d+)', ['node']).node as SMALLINT) as source_node,
    NULL as dest_node,
    CAST(REGEXP_EXTRACT(pivoted.names, 'SMB_(\d)', ['node']).node as SMALLINT) as reach_number,
  FROM pivoted
  WHERE names LIKE 'SMB_%'
)

-- Combine all events
SELECT * FROM flow_events
UNION ALL
SELECT * FROM inflow_events
UNION ALL
SELECT * FROM sconc_events
UNION ALL
SELECT * FROM salt_events
UNION ALL
SELECT * FROM smb_events
ORDER BY event_date, unit, reach_number;
