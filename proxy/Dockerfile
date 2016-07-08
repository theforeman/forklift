FROM ruby:2.3

RUN apt-get update
RUN apt-get install -y --force-yes build-essential wget git
RUN apt-get install -y --force-yes zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev
RUN apt-get install -y --force-yes libaugeas-ruby pkg-config libaugeas-dev
RUN apt-get update && apt-get install -y libvirt-bin libvirt-dev libkrb5-dev --no-install-recommends 
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

RUN git clone https://github.com/theforeman/smart-proxy.git /usr/src/app
RUN bundle
RUN chmod a+x /usr/src/app/bin/smart-proxy
RUN mkdir -p /var/log/foreman-proxy
RUN touch /var/log/foreman-proxy/proxy.log
ADD settings.yml config/settings.yml
