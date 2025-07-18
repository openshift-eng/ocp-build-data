FROM registry.ci.openshift.org/ocp/4.20:base-rhel9

RUN free -m

RUN cat /proc/cpuinfo
