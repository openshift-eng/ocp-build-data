# This base image is layered on by the logging elasticsearch image.
FROM elasticsearch:5.6.16-5.1587469481
# elasticsearch-container(https://brewweb.engineering.redhat.com/brew/packageinfo?packageID=67545)
# what we really want is the latest build of this package, which is a freshmaker
# build. freshmaker builds don't get a useful tag like "latest" or "5.6.16"
# so the old update-base-images implementation used to look up the tag from brew.
# doozer can't do that; this could get an updated freshmaker build at some
# point, in which case we might need to move to that. but it seems unlikely.

USER root
RUN echo 'skip_missing_names_on_install=0' >> /etc/yum.conf \
 && yum update -y  \
 && yum clean all
USER 1000
