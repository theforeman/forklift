FROM pulp/base:latest

# we make the images available on port 80 for this non-secure demo, so docker
# won't complain about SSL validation during "docker pull"
#ADD docker.conf /etc/pulp/vhosts80/docker.conf
#RUN rm /etc/httpd/conf.d/pulp_docker.conf
#ADD pulp_docker.conf /etc/httpd/conf.d/pulp_docker.conf

ADD httpdsed /httpdsed
ADD pulpsed /pulpsed
RUN sed -i -f /httpdsed /etc/httpd/conf/httpd.conf
RUN sed -i -f /pulpsed /etc/httpd/conf.d/pulp.conf

RUN chmod 777 -R /etc/httpd/logs
RUN rm -f /etc/httpd/conf.d/ssl.conf
