#!/bin/bash

# Dummy Nginx Access Log Generator
# Generates realistic geo-distributed traffic

LOG_FILE="./nginx/logs/access.log"

# Array of real public IPs with known geo data
declare -A IP_GEO=(
  # Format: "IP" "COUNTRY_CODE|COUNTRY_NAME|CITY|LAT|LON"
  ["8.8.8.8"]="US|United States|Mountain View|37.4056|-122.0775"
  ["1.1.1.1"]="AU|Australia|Sydney|-33.8688|151.2093"
  ["103.86.96.100"]="ID|Indonesia|Jakarta|-6.2088|106.8456"
  ["103.31.4.0"]="ID|Indonesia|Surabaya|-7.2575|112.7521"
  ["103.28.54.0"]="ID|Indonesia|Bandung|-6.9175|107.6191"
  ["103.150.100.0"]="ID|Indonesia|Medan|3.5952|98.6722"
  ["185.220.101.1"]="DE|Germany|Frankfurt|50.1109|8.6821"
  ["51.15.0.1"]="FR|France|Paris|48.8566|2.3522"
  ["104.16.0.1"]="US|United States|New York|40.7128|-74.0060"
  ["104.21.0.1"]="US|United States|Los Angeles|34.0522|-118.2437"
  ["13.107.21.200"]="US|United States|Chicago|41.8781|-87.6298"
  ["20.190.128.0"]="GB|United Kingdom|London|51.5074|-0.1278"
  ["40.82.128.0"]="NL|Netherlands|Amsterdam|52.3676|4.9041"
  ["52.94.76.0"]="JP|Japan|Tokyo|35.6762|139.6503"
  ["54.239.28.0"]="SG|Singapore|Singapore|1.3521|103.8198"
  ["13.229.188.59"]="SG|Singapore|Singapore|1.3521|103.8198"
  ["163.47.180.0"]="KR|South Korea|Seoul|37.5665|126.9780"
  ["202.12.29.0"]="CN|China|Beijing|39.9042|116.4074"
  ["103.1.206.0"]="IN|India|Mumbai|19.0760|72.8777"
  ["122.160.0.0"]="IN|India|New Delhi|28.6139|77.2090"
  ["196.207.45.0"]="KE|Kenya|Nairobi|-1.2921|36.8219"
  ["41.206.0.0"]="NG|Nigeria|Lagos|6.5244|3.3792"
  ["200.10.0.0"]="BR|Brazil|Sao Paulo|-23.5505|-46.6333"
  ["181.30.0.0"]="AR|Argentina|Buenos Aires|-34.6037|-58.3816"
  ["189.240.0.0"]="MX|Mexico|Mexico City|19.4326|-99.1332"
  ["45.116.0.0"]="TH|Thailand|Bangkok|13.7563|100.5018"
  ["103.9.76.0"]="MY|Malaysia|Kuala Lumpur|3.1390|101.6869"
  ["103.253.0.0"]="PH|Philippines|Manila|14.5995|120.9842"
  ["103.80.0.0"]="VN|Vietnam|Ho Chi Minh City|10.8231|106.6297"
  ["196.1.100.0"]="ZA|South Africa|Cape Town|-33.9249|18.4241"
)

METHODS=("GET" "GET" "GET" "GET" "POST" "GET" "GET")
PATHS=("/" "/api/data" "/health" "/metrics" "/api/login" "/static/app.js" "/favicon.ico" "/api/users" "/dashboard")
STATUSES=("200" "200" "200" "200" "200" "301" "404" "200" "403")
HTTP_VERSIONS=("1.1" "1.1" "2.0" "1.1")

IPS=("${!IP_GEO[@]}")

generate_request_time() {
  echo "0.00$(shuf -i 1-999 -n 1)"
}

generate_log_line() {
  local ip="${IPS[$RANDOM % ${#IPS[@]}]}"
  local geo="${IP_GEO[$ip]}"

  IFS='|' read -r country_code country_name city lat lon <<< "$geo"

  local method="${METHODS[$RANDOM % ${#METHODS[@]}]}"
  local path="${PATHS[$RANDOM % ${#PATHS[@]}]}"
  local status="${STATUSES[$RANDOM % ${#STATUSES[@]}]}"
  local http_ver="${HTTP_VERSIONS[$RANDOM % ${#HTTP_VERSIONS[@]}]}"
  local req_time=$(generate_request_time)

  echo "$ip $status $req_time \"$method $path HTTP/$http_ver\" \"$country_code\" \"$country_name\" \"$city\" $lat $lon"
}

# Mode 1: Burst — inject N lines immediately
burst_mode() {
  local count=${1:-100}
  echo "[*] Injecting $count log lines into $LOG_FILE ..."
  for i in $(seq 1 $count); do
    generate_log_line
  done | docker exec -i nginx bash -c "cat >> /var/log/nginx/access.log"
  echo "[✓] Done! Injected $count lines."
}

# Mode 2: Stream — inject continuously
stream_mode() {
  local interval=${1:-2}
  local count=${2:-0}
  local i=0
  echo "[*] Streaming log lines every ${interval}s ... (Ctrl+C to stop)"
  while true; do
    line=$(generate_log_line)
    echo "$line" | docker exec -i nginx bash -c "cat >> /var/log/nginx/access.log"
    echo "[+] $line"
    ((i++))
    [[ $count -gt 0 && $i -ge $count ]] && break
    sleep $interval
  done
  echo "[✓] Done!"
}

# CLI
case "${1:-burst}" in
  burst)
    burst_mode "${2:-100}"
    ;;
  stream)
    stream_mode "${2:-2}" "${3:-0}"
    ;;
  *)
    echo "Usage:"
    echo "  $0 burst [count]         # inject N lines at once (default: 100)"
    echo "  $0 stream [interval] [count]  # stream lines every N seconds"
    echo ""
    echo "Examples:"
    echo "  $0 burst 200             # inject 200 lines"
    echo "  $0 stream 1 50           # inject 1 line/sec for 50 lines"
    echo "  $0 stream 0.5            # inject 2 lines/sec forever"
    ;;
esac