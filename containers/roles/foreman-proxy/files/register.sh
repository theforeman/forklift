#!/bin/bash

curl -s -H "Content-Type: application/json" -X POST -d "{\"name\":\"foreman-proxy\",\"url\":\"http://${FOREMAN_PROXY_SERVICE_HOST}:8080\"}" -u admin:changeme http://$FOREMAN_SERVICE_HOST:8080/api/v2/smart_proxies
