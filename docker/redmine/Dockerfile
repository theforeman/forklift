FROM centos:7
MAINTAINER Eric Helms

RUN yum -y install vim ruby ruby-devel gcc make libxml2-devel libxslt-devel postgresql-devel libvirt-devel wget git mysql-devel ImageMagick-devel
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
RUN \curl -sSL https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c "rvm install 1.9.3"
RUN /bin/bash -l -c "rvm --default use 1.9.3"
RUN /bin/bash -l -c "gem install bundler --no-ri --no-rdoc"

RUN git clone https://github.com/theforeman/redmine.git

WORKDIR /redmine

RUN cp -f "Gemfile.lock.ruby-1.9" Gemfile.lock
RUN cp config/database.yml-1.9 config/database.yml

RUN /bin/bash -l -c "bundle install"

WORKDIR /

ADD run.sh /run.sh

CMD [ "/run.sh" ]
