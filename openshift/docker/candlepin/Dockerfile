FROM centos:7

RUN yum -y install https://fedorapeople.org/groups/katello/releases/yum/nightly/katello/el7/x86_64/katello-repos-latest.rpm
RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

RUN yum -y install candlepin
RUN yum -y install openssl

RUN wget -O /usr/share/candlepin/cpsetup https://raw.githubusercontent.com/candlepin/candlepin/master/server/code/setup/cpsetup
RUN wget -O /usr/share/candlepin/cpdb https://raw.githubusercontent.com/candlepin/candlepin/master/server/code/setup/cpdb

ADD setup.sh /setup.sh
