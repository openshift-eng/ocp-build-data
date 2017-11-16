# This should be a standard docker file which can be used for centos & CI builds.
# Important Restrictions:
# During a build in brew, the Dockerfile will not be able access external resources (e.g. wget/curl). All
# content for the image must be derived from installing RPMs available from RPM building group members.


# The FROM field specified in the upstream dockerfile should make sense for centos builds.
# It will be overwritten for brew builds by the oit utility. In this case, for example,
# oit is configured to make the FROM field specify a RHEL image base.
FROM centos:7

# Normal dockerfile content
ENV SOME_ENV=2

# Specify any labels you want. They can be overridden by oit metadata if necessary
# for RHEL based images.
LABEL   myutil_mode=nifty

# OIT can also be used to replace origin specific strings with values appropriate for OCP.
# For example, OIT could be configured to replace this string with "some_atomic_openshift_string"
LABEL   some_origin_string=value

# You can do whatever you want to enable/disable repos for centos/CI; however,
# when building in brew, these commands will be effectively ignored.
# The only repos that will matter during a brew build are described in group.yml.
RUN yum-config-manager --disable epel >/dev/null || : && \
    yum-config-manager --enable rhel-7-server-ose-onlineint-rpms

# Many common RPM packages are tagged/available for our builds in OSBS, but if you need something
# exotic, notify the CD team well in advance of trying to pull it into your Dockerfile.
# The repos that will be enabled in brew can be seen in group.yml. Work with CD if you
# need non-standard repos enabled.
RUN INSTALL_PKGS="dejavu-sans-fonts wget rsync gettext git tar zip unzip java-1.8.0-openjdk" && \
    yum install -y $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all  && \
    localedef -f UTF-8 -i en_US en_US.UTF-8

# Anything you run, needs to be able to run offline. You won't have standard network connectivity during a build.
RUN echo "Running offline!"


