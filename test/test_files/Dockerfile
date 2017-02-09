FROM centos:7
MAINTAINER ttcopy developers <https://github.com/greymd/ttcopy>
RUN yum install -y squid

# Default port of squid
EXPOSE 3128

CMD ["/usr/sbin/squid","-N"]
