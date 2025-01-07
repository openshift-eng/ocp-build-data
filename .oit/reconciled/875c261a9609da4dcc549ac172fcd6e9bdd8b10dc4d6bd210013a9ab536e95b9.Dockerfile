# This is a base image for supporting a nodejs app that runs on it.
# The same Dockerfile should serve for most versions of nodejs.
FROM nodejs
# rhscl/nodejs-6-rhel7 from rh-nodejs6-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=67372)
# rhscl/nodejs-10-rhel7 from rh-nodejs10-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=70335)
# ubi8/nodejs from from nodejs-10-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=69969)

USER root
RUN echo 'skip_missing_names_on_install=0' >> /etc/yum.conf \
 && yum update -y  \
 && yum clean all
USER 1001
