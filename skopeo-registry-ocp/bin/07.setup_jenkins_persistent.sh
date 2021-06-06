#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID GIT_USER GIT_PASSWORD"
    echo "  Example: $0 demo emailid@email.com EmailPassword"
    exit 1
fi

GUID=$1
GIT_USER=$2
GIT_PASSWORD=$3
echo "Setting up Jenkins in project ${GUID}-jenkins"

oc project $GUID-jenkins

# Leverage the credentials for pulling images from redhat registry
oc create -f 12821208-nkendyal-pull-secret.yml -n ${GUID}-jenkins
oc secrets link builder 12821208-nkendyal-pull-secret -n ${GUID}-jenkins

# Create the jenkins instance
oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi --param DISABLE_ADMINISTRATIVE_MONITORS=true -n ${GUID}-jenkins
oc set resources dc jenkins --limits=memory=2Gi,cpu=2 --requests=memory=1Gi,cpu=500m -n ${GUID}-jenkins


oc new-build --strategy=docker -D $'FROM registry.access.redhat.com/ubi8/go-toolset:latest as builder\n
ENV SKOPEO_VERSION=v1.0.0\n
RUN git clone -b $SKOPEO_VERSION https://github.com/containers/skopeo.git && cd skopeo/ && make binary-local DISABLE_CGO=1\n
FROM registry.redhat.io/openshift4/ose-jenkins-agent-maven:latest as final\n
USER root\n
RUN mkdir /etc/containers\n
COPY --from=builder /opt/app-root/src/skopeo/default-policy.json /etc/containers/policy.json\n
COPY --from=builder /opt/app-root/src/skopeo/skopeo /usr/bin\n
USER 1001' --name=jenkins-agent-appdev -n ${GUID}-jenkins

# Set up ConfigMap with Jenkins Agent definition
oc create -f ./manifests/agent-cm.yaml -n ${GUID}-jenkins

echo "Checking if Jenkins Controller is Ready..."
while : ; do
  AVAILABLE_REPLICAS=$(oc get dc jenkins -n ${GUID}-jenkins -o=jsonpath='{.status.availableReplicas}')
  if [[ "$AVAILABLE_REPLICAS" == "1" ]]; then
    echo "...Yes. Jenkins is ready."
    break
  fi
  echo "...No. Sleeping 15 seconds."
  sleep 15
done

# Make sure that Jenkins Agent Build Pod has finished building
echo "Checking if Jenkins Agent Build Pod Finished Building..."
while : ; do
  AVAILABLE_REPLICAS=$(oc get pod jenkins-agent-appdev-1-build -n ${GUID}-jenkins -o=jsonpath='{.status.phase}')
  if [[ "$AVAILABLE_REPLICAS" == "Succeeded" ]]; then
    echo "...Yes. Jenkins Agent Build Pod has finished."
    break
  fi
  echo "...No. Sleeping 15 seconds."
  sleep 15
done

# Create the Build Config for the pipeline
oc create -f ./manifests/tasks-pipeline.yml -n ${GUID}-jenkins

# Set the GIT creds and pass it onto the Build Config
oc create secret generic git-secret --from-literal=username=${GIT_USER} --from-literal=password=${GIT_PASSWORD}
oc set build-secret --source bc/tasks-pipeline git-secret -n ${GUID}-jenkins
echo "Jenkins Setup Complete"