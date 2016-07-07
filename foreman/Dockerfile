FROM ruby:2.3

# see update.sh for why all "apt-get install"s have to stay as one long line
RUN apt-get update && apt-get install -y nodejs --no-install-recommends && rm -rf /var/lib/apt/lists/*

# see http://guides.rubyonrails.org/command_line.html#rails-dbconsole
RUN apt-get update && apt-get install -y mysql-client postgresql-client sqlite3 libvirt-bin libvirt-dev --no-install-recommends && rm -rf /var/lib/apt/lists/*

ENV RAILS_VERSION 4.2.6

RUN gem install rails --version "$RAILS_VERSION"

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

RUN git clone https://github.com/theforeman/foreman.git /usr/src/app
RUN bundle
RUN cp config/settings.yaml.example config/settings.yaml
ADD database.yml config/database.yml
#EXPOSE 3000
#ENTRYPOINT ["rails", "server", "-b", "0.0.0.0"]
