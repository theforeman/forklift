FROM centos:7

ENV RAILS_ENV="production"
ENV FOREMAN_APIPIE_LANGS="en"
ARG REPO="theforeman/foreman"
ARG BRANCH="develop"
# Allow adding additional build packages
ARG ADDITIONAL_BUILD_PACKAGES=""
ARG BUNDLER_SKIPPED_GROUPS="mysql:test:mysql2:development:sqlite:jenkins:openid:libvirt:journald"

WORKDIR /usr/share/foreman

# Downloading foreman source code, using github archive option as its faster
RUN curl -s https://codeload.github.com/${REPO}/tar.gz/${BRANCH} |tar xzf - --strip-components=1

# Deploy DB configuration, defaulting to postgresql
ADD container-assets/database.yml config/database.yml

# Plugin configuration section
# if you want additional plugins please edit the file below
ADD container-assets/Gemfile.local.rb bundler.d/Gemfile.local.rb

# Foreman setting
ADD container-assets/settings.yaml config/settings.yaml

# Build script
ADD container-assets/setup tmp/setup
ADD container-assets/build tmp/build
RUN tmp/setup

EXPOSE 3000/tcp
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
