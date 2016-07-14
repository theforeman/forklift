FROM fedora:latest
#RUN dnf -y update
RUN dnf -y install ruby{,-devel,gems} rubygem-{bundler,rdoc} git gcc-c++ make hostname
RUN dnf clean all
MAINTAINER ohadlevy@gmail.com

ENV REPO_URL=https://github.com/theforeman/smart-proxy.git

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

RUN git clone ${REPO_URL} /usr/src/app
RUN mkdir /usr/src/app/logs
RUN bundle --without bmc:development:krb5:libvirt:puppet_proxy_legacy:test:windows
#RUN chmod a+x /usr/src/app/bin/smart-proxy
ADD settings.yml config/settings.yml
