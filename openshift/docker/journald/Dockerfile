FROM centos/systemd

RUN systemctl enable systemd-journald.service

EXPOSE 514

CMD ["/usr/sbin/init"]
