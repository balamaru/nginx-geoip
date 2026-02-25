## 1. measurement
```sh
from(bucket: "nginx")
  |> range(start: -1h)
  |> limit(n: 10)
```
## 2. list all field
```sh
from(bucket: "nginx")
  |> range(start: -1h)
  |> keep(columns: ["_measurement", "_field"])
  |> distinct(column: "_field")
```

## 3. Ceck if geo saved as string
```sh
from(bucket: "nginx")
  |> range(start: -1h)
  |> filter(fn: (r) => r._field =~ /lat|lon/)
  |> limit(n: 20)
```

## 4. 
```sh
from(bucket: "nginx")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "nginx_access")
  |> filter(fn: (r) => r.country_code != "-")
  |> pivot(rowKey: ["_time"], columnKey: ["_field"], valueColumn: "_value")
  |> keep(columns: ["_time", "client_ip", "country_code", "country_name", "city_name", "latitude", "longitude"])
```

## 5. should be in geo map
```sh
from(bucket: "nginx")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "nginx_access")
  |> filter(fn: (r) => r._field == "latitude" or r._field == "longitude")
  |> pivot(rowKey: ["_time", "city_name", "country_code", "country_name"], columnKey: ["_field"], valueColumn: "_value")
  |> map(fn: (r) => ({
      r with
      latitude: float(v: r.latitude),
      longitude: float(v: r.longitude)
  }))
  |> keep(columns: ["_time", "latitude", "longitude", "city_name", "country_code", "country_name"])
```

## 6. 
```sh
    from(bucket: "nginx")
    |> range(start: -1h)
    |> filter(fn: (r) => r._measurement == "nginx_access")
    |> filter(fn: (r) => r._field == "longitude")
    |> limit(n: 10)
```

## 7. 
```sh
from(bucket: "nginx")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "nginx_access")
  |> filter(fn: (r) => r._field == "latitude" or r._field == "longitude")
  |> pivot(rowKey: ["_time", "city_name", "country_code", "country_name"], columnKey: ["_field"], valueColumn: "_value")
  |> map(fn: (r) => ({
      r with
      latitude: float(v: r.latitude),
      longitude: float(v: r.longitude)
  }))
  |> keep(columns: ["_time", "latitude", "longitude", "city_name", "country_code", "country_name"])
```
output
0 series returned
## 8. 
```sh
from(bucket: "nginx")
  |> range(start: -5m)
  |> filter(fn: (r) => r._measurement == "nginx_access")
  |> filter(fn: (r) => r._field == "latitude" or r._field == "longitude")
```
output
0 series returned

## 9. swith 5
```sh
from(bucket: "nginx")
  |> range(start: -24h)
  |> filter(fn: (r) => r._measurement == "nginx_access")
  |> filter(fn: (r) => r._field == "latitude" or r._field == "longitude")
  |> pivot(rowKey: ["_time", "city_name", "country_code", "country_name"], columnKey: ["_field"], valueColumn: "_value")
  |> map(fn: (r) => ({
      r with
      latitude: float(v: r.latitude),
      longitude: float(v: r.longitude)
  }))
  |> keep(columns: ["_time", "latitude", "longitude", "city_name", "country_code", "country_name"])
```