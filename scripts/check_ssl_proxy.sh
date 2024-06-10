#!/bin/bash

# Usage: check_ssl_proxy.sh <hostname> <port> <method> [username] [password] [certificate_path]
HOST=$1
PORT=$2
METHOD=$3
USERNAME=$4
PASSWORD=$5
CERTIFICATE_PATH=$6

# Function to check if the proxy server is running
check_proxy() {
  local host=$1
  local port=$2
  local method=$3
  local username=$4
  local password=$5
  local cert_path=$6

  # Build curl command with optional authentication and certificate verification
  local curl_cmd="curl --silent --show-error --verbose --connect-timeout 5"

  if [ "$method" == "HTTPS" ]; then
    curl_cmd+=" https://$host:$port"
  else
    curl_cmd+=" http://$host:$port"
  fi

  # Add authentication if username and password are provided
  if [ -n "$username" ] && [ -n "$password" ]; then
    curl_cmd+=" --proxy-user $username:$password"
  fi

  # Add certificate verification if certificate path is provided (for HTTPS)
  if [ "$method" == "HTTPS" ] && [ -n "$cert_path" ]; then
    curl_cmd+=" --cacert $cert_path"
  fi

  # Execute curl command and capture response
  response=$(eval $curl_cmd 2>&1)
  status=$?

  if [ $status -eq 0 ]; then
    echo "$method Proxy server is running at $method://$host:$port"
  else
    echo "Failed to connect to $method Proxy server at $method://$host:$port"
    echo "Error details:"

    if [[ $response == *"Failed to connect to"* ]]; then
      echo "Connection failure. Please check if the server is running and the network adapter is correct."
    elif [[ $response == *"SSL certificate problem"* ]]; then
      echo "SSL certificate verification failed. Details:"
      echo "$response" | grep "SSL certificate problem"
    elif [[ $response == *"Could not resolve host"* ]]; then
      echo "Could not resolve host. Please check the hostname and try again."
    else
      echo "$response"
    fi
  fi

  # Detailed certificate information
  if [ "$method" == "HTTPS" ] && [ -n "$cert_path" ]; then
    echo "Validating SSL certificate with OpenSSL..."
    openssl x509 -in $cert_path -noout -text
  fi
}

# Check if hostname, port, and method are provided
if [ -z "$HOST" ] || [ -z "$PORT" ] || [ -z "$METHOD" ]; then
  echo "Usage: $0 <hostname> <port> <method> [username] [password] [certificate_path]"
  echo "Method must be either HTTP or HTTPS"
  exit 1
fi

# Call the check_proxy function
check_proxy $HOST $PORT $METHOD $USERNAME $PASSWORD $CERTIFICATE_PATH
