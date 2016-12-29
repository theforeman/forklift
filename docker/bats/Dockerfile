FROM centos:7

RUN yum -y install https://fedorapeople.org/groups/katello/releases/yum/nightly/katello/el7/x86_64/katello-repos-latest.rpm
RUN yum -y install http://yum.theforeman.org/nightly/el7/x86_64/foreman-release.rpm

RUN yum -y install git wget
RUN yum -y install foreman-release-scl
RUN yum -y install tfm-rubygem-hammer_cli_katello

ADD foreman.yml /etc/hammer/cli.modules.d/foreman.yml

WORKDIR /root
RUN git clone https://github.com/ehelms/forklift -b bats-update
RUN git clone https://github.com/sstephenson/bats.git
RUN bats/install.sh /usr/local
RUN forklift/bats/install.sh /usr/local

ADD run.sh /run.sh

CMD ["/run.sh"]
