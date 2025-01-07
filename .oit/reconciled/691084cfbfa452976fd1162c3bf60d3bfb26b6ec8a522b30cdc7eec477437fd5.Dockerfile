# This is a base image for supporting a python app that runs on it.
# The same Dockerfile should serve for most versions of python.
FROM python
# rhscl/python-36-rhel7 from rh-python36-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=67385)
# ubi8/python-36 from python-36-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=69964)

USER root
RUN echo 'skip_missing_names_on_install=0' >> /etc/yum.conf \
 && yum update -y  \
 && yum clean all
USER 1001
