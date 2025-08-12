#!/bin/bash
URL="$1"
if [ -z "$URL" ]; then
  echo "Usage: $0 <url>"
  exit 1
fi

while true; do
  STATUS=$(curl -o /dev/null -sS \
    --connect-timeout 3 \
    --max-time 5 \
    --http1.1 \
    -H 'Connection: close' \
    -w "%{http_code}" "$URL")

  TS=$(date '+%Y-%m-%d %H:%M:%S')

  if [[ "$STATUS" =~ ^2[0-9]{2}$ ]]; then
    echo -e "$TS \033[0;32m$STATUS\033[0m"
  elif [[ "$STATUS" == "000" ]]; then
    echo -e "$TS \033[0;31m$STATUS (timeout/error)\033[0m"
  else
    echo -e "$TS \033[0;31m$STATUS\033[0m"
  fi

done