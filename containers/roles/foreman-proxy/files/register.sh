#!/bin/bash

(
  data="{\"name\":\"${FOREMAN_PROXY_SERVICE_HOST}\",\"url\":\"http://${FOREMAN_PROXY_SERVICE_HOST}:8080\"}"
  url="http://$FOREMAN_SERVICE_HOST:8080/api/v2/smart_proxies"
  credentials="admin:changeme"

  tries=0

	while [ $tries -lt 180 ]; do
		tries=$((tries + 1))
		echo "Attempting to register smart proxy"
		(curl -f -H "Content-Type: application/json" -X POST -d $data -u $credentials $url)
		status=$?

		if [ $status -eq 0 ]; then
			echo "Smart proxy registered"
			exit 0
		elif [ $status -eq 22 ]; then
			echo "Smart proxy already registered"
			exit 0
		else
			echo "Foreman unreachable, sleeping to try again"
			sleep 5
		fi
	done

	echo "Smart proxy timed out attempting to register"
	exit 1
) >> /tmp/register 2>&1
