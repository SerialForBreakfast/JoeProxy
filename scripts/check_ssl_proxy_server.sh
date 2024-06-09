#!/bin/bash

# Usage: check_ssl_proxy.sh <hostname> <port>
HOST=$1
PORT=$2

# Function to check if the SSL proxy server is running
check_ssl_proxy() {
  local host=$1
  local port=$2

  # Using curl to check the SSL connection
  response=$(curl --silent --connect-timeout 5 https://$host:$port)

  if [ $? -eq 0 ]; then
    echo "SSL Proxy server is running at https://$host:$port"
  else
    echo "Failed to connect to SSL Proxy server at https://$host:$port"
  fi
}

# Check if hostname and port are provided
if [ -z "$HOST" ] || [ -z "$PORT" ]; then
  echo "Usage: $0 <hostname> <port>"
  exit 1
fi

# Call the check_ssl_proxy function
check_ssl_proxy $HOST $PORT
