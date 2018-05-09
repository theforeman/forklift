FROM centos:7

ENV RAILS_ENV="production"
ENV FOREMAN_APIPIE_LANGS="en"
ARG REPO="theforeman/foreman"
ARG BRANCH="develop"
# Allow adding additional build packages
ARG ADDITIONAL_BUILD_PACKAGES=""
ARG BUNDLER_SKIPPED_GROUPS="mysql:test:mysql2:development:sqlite:jenkins:openid:libvirt:journald"

ENV HOME=/usr/share/foreman

WORKDIR $HOME
RUN groupadd -r foreman -f -g 1001 && \
    useradd -u 1001 -r -g foreman -d ${HOME} -s /sbin/nologin \
    -c "Foreman Application User" foreman && \
    chown -R 1001:1001 ${HOME}

USER foreman

# Downloading foreman source code, using github archive option as its faster
RUN curl -s https://codeload.github.com/${REPO}/tar.gz/${BRANCH} |tar xzf - --strip-components=1 && mkdir tmp

# Deploy DB configuration, defaulting to postgresql
COPY container-assets/database.yml config/database.yml

# Plugin configuration section
# if you want additional plugins please edit the file below
COPY container-assets/Gemfile.local.rb bundler.d/Gemfile.local.rb

# Foreman setting
COPY container-assets/settings.yaml config/settings.yaml

USER root
# Build script
COPY container-assets/setup tmp/setup
COPY container-assets/build tmp/build
RUN tmp/setup

COPY container-assets/entrypoint.sh /usr/bin/entrypoint
COPY container-assets/wait_on_postgres.py /usr/bin/wait_on_postgres
COPY container-assets/create_qpid_queue.sh /usr/bin/create_qpid_queue

# Allow openshift to run as a random user.
RUN chgrp -R 0 $HOME && \
    chmod -R g=u $HOME

# Foreman UID
USER 1001
EXPOSE 3000/tcp
ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["server"]
