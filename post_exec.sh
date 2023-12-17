#! /bin/sh

# This script is executed after rsnapshot has run and pings a health check URL.

source ~/env

echo ""
echo "Ping health check URL"
curl -sSf "${HEALTH_CHECK_URL}"
