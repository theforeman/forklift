# Foreman docker-compose

Docker compose of Foreman (develop branch), Smart Proxy (develop branch) and Postgres

## Installation

Install `docker-compose` from [docker compose](https://docs.docker.com/compose/install/)

cd into this directory and run `docker-compose up`. This will build postgres image and Foreman (develop branch) image.

Once completed run `docker-compose run foreman rake db:migrate` and `foreman-compose run rake db:seed`

Please note that `docker-compose up` binds your localhost:3000 to the container's port 3000, so once complete you can go to http://localhost:3000
