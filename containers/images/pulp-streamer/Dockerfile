FROM quay.io/foreman/pulp:latest

RUN echo "tsflags=nodocs" >> /etc/yum.conf && \
    yum -y install epel-release && \
		yum -y install python-pulp-streamer && \
		yum clean all

COPY container-assets/streamer.conf /etc/pulp/streamer.conf
COPY container-assets/entrypoint.sh /usr/bin/entrypoint.sh
COPY container-assets/start_pulp_streamer.sh /usr/bin/start_pulp_streamer.sh

ADD https://raw.githubusercontent.com/ehelms/pulp/127d099833ec8d3c757db2b28b5fd14a2b6d7077/streamer/usr/share/pulp/wsgi/streamer.tac /usr/share/pulp/wsgi/streamer.tac

CMD ["/usr/bin/start_pulp_streamer.sh"]
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
