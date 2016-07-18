# Foreman docker-compose

Docker compose of Foreman in a LB (using haproxy) setup, including basic client (fact uploads), postgres and memcache.

## Installation

Install `docker-compose` from [docker compose](https://docs.docker.com/compose/install/) (or via native packaging)

cd into this directory and run `docker-compose up`. This will build postgres image and Foreman (develop branch) image.

Once the environment is up, you may simply login to `http://localhost`. SSL is disabled for this deployment.

## Known issues

### fact uploading

the client container can upload facts, however, you would need to change the following setting:
```
restrict_registered_smart_proxies=false
require_ssl_smart_proxies=false
```


### SELinux Denials


the way haproxy auto configure itself based on scale, is by quering docker itself, this raises a selinux alert, if you want haproxy to autoconfigure currently you need to setenfore=0.

Please note that `docker-compose up -d` binds your localhost:80 to the haproxy container port 80, so once complete you can go to ```http://localhost```


Once completed you may scale your services - e.g. `docker-compose scale foreman=3 client=10`
