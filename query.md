## 1. Visitor World Map
- Vizualitation map : geomap
- Style sizes : hit_count
```sh
lat = from(bucket: "nginx")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "nginx_access")
  |> filter(fn: (r) => r._field == "latitude")
  |> group(columns: ["city_name", "country_code"])
  |> first()
  |> rename(columns: {_value: "latitude"})
  |> drop(columns: ["_time"])

lon = from(bucket: "nginx")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "nginx_access")
  |> filter(fn: (r) => r._field == "longitude")
  |> group(columns: ["city_name", "country_code"])
  |> first()
  |> rename(columns: {_value: "longitude"})
  |> drop(columns: ["_time"])

hits = from(bucket: "nginx")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "nginx_access")
  |> filter(fn: (r) => r._field == "status")
  |> group(columns: ["city_name", "country_code"])
  |> count()
  |> rename(columns: {_value: "hit_count"})
  |> drop(columns: ["_time", "_field"])

j1 = join(tables: {lat: lat, lon: lon}, on: ["city_name", "country_code"])
join(tables: {j1: j1, hits: hits}, on: ["city_name", "country_code"])
  |> map(fn: (r) => ({
      _time: now(),
      city_name: r.city_name,
      country_code: r.country_code,
      latitude: float(v: r.latitude),
      longitude: float(v: r.longitude),
      hit_count: r.hit_count
  }))
  |> group()
```
## 2. Top Countries by Request Count
- Viz type : Barchart
- 
```sh
from(bucket: "nginx")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "nginx_access")
  |> filter(fn: (r) => r._field == "status")
  |> filter(fn: (r) => r.country_code != "-")
  |> group(columns: ["country_code", "country_name"])
  |> count()
  |> group()
  |> sort(columns: ["_value"], desc: true)
  |> limit(n: 10)
```

## 3. Top Cities
- Viz type : Barchart
```sh
from(bucket: "nginx")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "nginx_access")
  |> filter(fn: (r) => r._field == "status")
  |> filter(fn: (r) => r.city_name != "-")
  |> group(columns: ["city_name", "country_code"])
  |> count()
  |> group()
  |> sort(columns: ["_value"], desc: true)
  |> limit(n: 10)
```

## 4. Avg Response Time
- Viz type : Gauge
- Standard options.unit : seconds (s)
```sh
from(bucket: "nginx")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "nginx_access")
  |> filter(fn: (r) => r._field == "request_time")
  |> mean()
  |> map(fn: (r) => ({ _value: r._value, _field: "Avg Response Time" }))
```

## 5. Total request
- Viz type : stat
- Standard options.unit : unit
```sh
from(bucket: "nginx")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "nginx_access")
  |> filter(fn: (r) => r._field == "status")
  |> count()
  |> map(fn: (r) => ({ _value: r._value, _field: "Total Requests" }))
```

## 6. Response Time Over Time
- Viz type : time series
```sh
from(bucket: "nginx")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "nginx_access")
  |> filter(fn: (r) => r._field == "request_time")
  |> aggregateWindow(every: v.windowPeriod, fn: count, createEmpty: false)
  |> map(fn: (r) => ({ r with _field: "Requests" }))
  |> drop(columns: ["_measurement", "_start", "_stop", "env", "host", "instance", "service", "name", "path"])
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
```

## 7. Request Rate Over Time
- Viz type : time series
```sh
from(bucket: "nginx")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r._measurement == "nginx_access")
  |> filter(fn: (r) => r._field == "status")
  |> aggregateWindow(every: v.windowPeriod, fn: count, createEmpty: false)
  |> map(fn: (r) => ({ r with _field: "Requests" }))
  |> drop(columns: ["_measurement", "_start", "_stop", "env", "host", "instance", "service", "name", "path"])
  |> yield(name: "request_rate")
```
