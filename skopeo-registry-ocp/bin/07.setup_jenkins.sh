#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/redhat-gpte-devopsautomation/advdev_homework_template.git shared.na.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

oc project $GUID-jenkins
oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi --param DISABLE_ADMINISTRATIVE_MONITORS=true -n ${GUID}-jenkins
oc set resources dc jenkins --limits=memory=2Gi,cpu=2 --requests=memory=1Gi,cpu=500m -n ${GUID}-jenkins

oc create -f 12821208-nkendyal-pull-secret.yml -n ${GUID}-jenkins
oc secrets link builder 12821208-nkendyal-pull-secret -n ${GUID}-jenkins

oc new-build --strategy=docker -D $'FROM registry.access.redhat.com/ubi8/go-toolset:latest as builder\n
ENV SKOPEO_VERSION=v1.0.0\n
RUN git clone -b $SKOPEO_VERSION https://github.com/containers/skopeo.git && cd skopeo/ && make binary-local DISABLE_CGO=1\n
FROM registry.redhat.io/openshift4/ose-jenkins-agent-maven:latest as final\n
USER root\n
RUN mkdir /etc/containers\n
COPY --from=builder /opt/app-root/src/skopeo/default-policy.json /etc/containers/policy.json\n
COPY --from=builder /opt/app-root/src/skopeo/skopeo /usr/bin\n
USER 1001' --name=jenkins-agent-appdev -n ${GUID}-jenkins

oc create secret generic git-secret --from-literal=username=subscribeken@gmail.com --from-literal=password="Login4me@"


#oc new-app --template=eap72-basic-s2i --param APPLICATION_NAME=tasks --param SOURCE_REPOSITORY_URL=%%git_repo%% --param SOURCE_REPOSITORY_REF=master --param CONTEXT_DIR=/ --param MAVEN_MIRROR_URL=https://homework-nexus-registry.apps.shared-na4.na4.openshift.opentlc.com/repository/maven-all-public
#oc set build-secret --source bc/tasks git-secret
# Set up ConfigMap with Jenkins Agent definition
oc create -f ./manifests/agent-cm.yaml -n ${GUID}-jenkins


while : ; do
  echo "Checking if Jenkins is Ready..."
  AVAILABLE_REPLICAS=$(oc get dc jenkins -n ${GUID}-jenkins -o=jsonpath='{.status.availableReplicas}')
  if [[ "$AVAILABLE_REPLICAS" == "1" ]]; then
    echo "...Yes. Jenkins is ready."
    break
  fi
  echo "...no. Sleeping 10 seconds."
  sleep 10
done

# Make sure that Jenkins Agent Build Pod has finished building
while : ; do
  echo "Checking if Jenkins Agent Build Pod has finished building..."
  AVAILABLE_REPLICAS=$(oc get pod jenkins-agent-appdev-1-build -n ${GUID}-jenkins -o=jsonpath='{.status.phase}')
  if [[ "$AVAILABLE_REPLICAS" == "Succeeded" ]]; then
    echo "...Yes. Jenkins Agent Build Pod has finished."
    break
  fi
  echo "...no. Sleeping 10 seconds."
  sleep 10
done

oc create -f ./manifests/tasks-pipeline.yml -n ${GUID}-jenkins
oc set build-secret --source bc/tasks-pipeline git-secret -n ${GUID}-jenkins
