FROM fedora:latest
#RUN dnf -y update
RUN dnf -y install ruby{,-devel,gems} rubygem-{nokogiri,bundler,unf_ext,rdoc} redhat-rpm-config nodejs npm git postgresql-devel gcc-c++ make hostname sqlite-devel
RUN dnf clean all
LABEL MAINTAINER="ohadlevy@gmail.com"

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ENV RAILS_ENV=production
ENV FOREMAN_APIPIE_LANGS=en
ENV REPO_URL=https://github.com/foreman/foreman.git
ENV REPO_BRANCH=develop

#TODO: support local path instead of checkout
RUN git clone -b ${REPO_BRANCH} ${REPO_URL} /usr/src/app
#RUN touch config/initializers/local_secret_token.rb
RUN [ -e 'package.json' ] && npm install || exit 0
ADD Gemfile.local.rb bundler.d/Gemfile.local.rb
ADD settings.yaml config/settings.yaml
RUN bundle --without mysql:test:development:mysql2:jenkins:openid:libvirt

ADD build_database.yml config/database.yml
RUN bundle exec rake db:create
RUN bundle exec rake db:migrate
RUN bundle exec rake security:generate_token
RUN bundle exec rake security:generate_encryption_key
RUN bundle exec rake assets:precompile
RUN bundle exec rake webpack:compile
RUN bundle exec rake apipie:cache:index

ADD database.yml config/database.yml
RUN chmod 777 -R /usr/src/app/tmp
