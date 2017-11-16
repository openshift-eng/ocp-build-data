# This should be a standard docker file which can be used for centos & CI builds.
# Important Restrictions:
# During a build in brew, the Dockerfile will not be able access external resources (e.g. wget/curl). All
# content for the image must be derived from installing RPMs available from RPM building group members.

# The FROM field will be managed automatically by OIT. In this case, the image will be based
# off of another OIT managed image. The field and tag will be managed automatically.
FROM openshift/myutil-base

# This should be a standard docker file which can be used for centos & CI builds.
# Important Restrictions:
# During a build in brew, the Dockerfile will not be able access external resources (e.g. wget/curl). All
# content for the image must be derived from installing RPMs available from RPM building group members.

# Files/directories in the same path as the Dockerfile will be available during the brew build.
COPY supporting-file.bin /etc/

USER 1001
ENTRYPOINT []
CMD ["/usr/bin/myutil"]


