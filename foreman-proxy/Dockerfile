FROM fedora:latest
LABEL MAINTAINER="shlomi@ben-hanna.com"
RUN dnf -y update
RUN dnf -y install ruby{,-devel,gems,-irb} rubygem-{nokogiri,bundler,unf_ext,rdoc} git redhat-rpm-config nodejs git postgresql-devel gcc-c++ make hostname
RUN dnf clean all

ENV REPO_URL=https://github.com/theforeman/smart-proxy.git

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

RUN git clone ${REPO_URL} /usr/src/app
RUN mkdir /usr/src/app/logs
ADD settings.yml config/settings.yml
ADD pulp.yml config/settings.d/pulp.yml
ADD Gemfile.local.rb bundler.d/Gemfile.local.rb
RUN bundle --without bmc:krb5:libvirt:puppet_proxy_legacy:test:windows 

ADD register.sh register.sh
