FROM quay.io/foreman/pulp:latest

RUN echo "tsflags=nodocs" >> /etc/yum.conf && \
    yum -y install epel-release && \
    yum -y install python-pulp-streamer && \
		yum clean all

RUN rm -f /etc/httpd/conf.d/pulp.conf /etc/httpd/conf.d/pulp_puppet.conf
RUN rm -f /etc/pki/tls/certs/localhost.crt /etc/pki/tls/private/localhost.key

RUN ln -s /var/lib/pulp/published /var/www/pub
RUN ln -s /etc/pki/pulp/certs/pulp.crt /etc/pki/tls/certs/localhost.crt
RUN ln -s /etc/pki/pulp/private/pulp.key /etc/pki/tls/private/localhost.key

RUN chown apache:apache /var/lib/pulp
RUN mkdir /var/www/html/pub && chown apache:apache -R /var/www/html

RUN sed -i 's/127.0.0.1/squid/g' /etc/httpd/conf.d/pulp_streamer.conf

COPY container-assets/content_wsgi.conf /etc/httpd/conf.d/content_wsgi.conf

ENTRYPOINT []
CMD ["httpd", "-D", "FOREGROUND"]
