FROM ubi8/nodejs-12

USER root
RUN echo 'skip_missing_names_on_install=0' >> /etc/yum.conf \
 && echo 'exclude=nodejs nodejs-docs npm' >> /etc/yum.conf \
 && yum update -y  \
 && yum clean all
USER 1001
