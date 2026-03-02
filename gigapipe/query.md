# 1. Access Logs Tables
1. Query
```sh
{job="nginx"}
| json
| __error__ = ""
```
2. Viz type : Tables
3. Transform
    - Extract fields :
        - Source → Line
        - Format → JSON
    - Organize fields
        - Hide and rename to measure

# 2. Visitor World Map
1. Query
```sh
sum by (geoip_latitude, geoip_longitude, geoip_city_name, geoip_country_code) (
  count_over_time(
    {job="nginx"}
    | json
    | __error__ = ""
    | geoip_latitude != ""
    | geoip_latitude != "0"
    [$__range]
  )
)
```
2. Viz Type : GeoMap
3. Transform
    - Labels to fields
        - Labels auto fill
    - Convert field type
        - geoip_latitude → Number
        - geoip_longitude → Number
    - Merge series/tables
    - Organize fields by name
        - geoip_latitude → lat
        - geoip_longitude → lon

# 3. Total Requests
1. Query
```sh
sum(count_over_time(
  {job="nginx"}
  | json
  | __error__ = ""
  [$__range]
))
```
2. Viz Type : Stat

# 4. HTTP Status Code Distribution
1. Viz Type : Pie
2. Query
```sh
sum by (status) (count_over_time(
  {job="nginx"}
  | json
  | __error__ = ""
  | status != ""
  [$__range]
))
```

# 5. Top uri
1. Viz type : bar chart
2. Query
```sh
sum by (request_uri) (
  count_over_time(
    {job="nginx"}
    | json
    | __error__ = ""
    | request_uri != ""
    | request_uri !~ "/nginx_status.*"
    [$__range]
  )
)
```
3. Transform
    - Reduce --> Last*
    - Sort By
    - Limit

# 6. Top Countries by Request Count
1. Viz Type : Bar chart
2. Query
```sh
sum by (geoip_country_name) (
  count_over_time(
    {job="nginx"}
    | json
    | __error__ = ""
    | geoip_country_name != ""
    | geoip_country_name != "-"
    [$__range]
  )
)
```
3. Transform
    - Reduce
    - Sort By
    - Limit

# 7. Top Cities by Request Count
1. Viz Type : Bar chart
2. Query
```sh
sum by (geoip_city_name) (
  count_over_time(
    {job="nginx"}
    | json
    | __error__ = ""
    | geoip_city_name != ""
    | geoip_city_name != "-"
    [$__range]
  )
)
```
3. Transform
    - Reduce
    - Sort By
    - Limit

# 8. Request Volume by HTTP Method
1. Viz type: Pie Chart
2. Query
```sh
sum by (request_method) (count_over_time(
  {job="nginx"}
  | json
  | __error__ = ""
  | request_method != ""
  [$__range]
))
```

# 9.  Bandwidth per Country (Not Available panel)
1. Viz: Bar chart
2. Query
```sh
logqltopk(10,
  sum by (geoip_country_name) (
    sum_over_time(
      {job="nginx"}
      | json
      | __error__ = ""
      | geoip_country_name != ""
      | unwrap bytes_sent
      | __error__ = ""
      [$__range]
    )
  )
)
```