---
title: The Reaches
queries:
    - sources/oasis/events.sql
---

![topo](/topo.png)

<Dropdown name=reach_number>
    <DropdownOption valueLabel="Reach 1" value="1" />
    <DropdownOption valueLabel="Reach 2" value="2" />
    <DropdownOption valueLabel="Reach 3" value="3" />
    <DropdownOption valueLabel="Reach 4" value="4" />
    <DropdownOption valueLabel="Reach 5" value="5" />
    <DropdownOption valueLabel="Reach 6" value="6" />
</Dropdown>

<DateRange
    name=event_range
    data=events
    dates=event_date
/>

<Dropdown name=event_type>
    <DropdownOption valueLabel="FLOW" value="FLOW" />
    <DropdownOption valueLabel="SALINITY" value="SALINITY" />
    <DropdownOption valueLabel="SALT" value="SALT" />
</Dropdown>

```sql reach_nodes
SELECT DISTINCT
    source_node
FROM
    events
WHERE
    event_date BETWEEN '${ inputs.event_range.start }' AND '${ inputs.event_range.end }'
    AND (reach_number = ${ inputs.reach_number.value } OR ${ inputs.reach_number.value } = NULL)
    AND (event_type = '${inputs.event_type.value}' OR '${inputs.event_type.value}' = NULL)
```

<Dropdown
    data={reach_nodes}
    name=node_multi
    value=source_node
    multiple=true
/>


```sql node_overview
SELECT
    *
FROM events
WHERE
    source_node IN ${inputs.node_multi.value}
    AND (event_type = '${inputs.event_type.value}' OR '${inputs.event_type.value}' = NULL)
```

<CalendarHeatmap
    data={node_overview}
    date=event_date
    value=amount
    colorScale={[
        ['rgb(254,234,159)', 'rgb(254,234,159)'],
        ['rgb(218,66,41)', 'rgb(218,66,41)']
    ]}
/>

```sql filtered_events
SELECT
    event_date,
    amount,
    unit,
    source_node,
    dest_node,
    reach_number
FROM
    events
WHERE
    event_date BETWEEN '${ inputs.event_range.start }' AND '${ inputs.event_range.end }'
    AND (reach_number = ${ inputs.reach_number.value } OR ${ inputs.reach_number.value } = NULL)
    AND (source_node IN ${inputs.node_multi.value} OR ${inputs.node_multi.value} = NULL)
    AND event_type = '${inputs.event_type.value}'
ORDER BY
    event_date ASC
```

<LineChart
    data={filtered_events}
    x=event_date
    y=amount
    series=source_node
/>