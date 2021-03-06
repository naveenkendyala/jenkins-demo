#!/bin/bash
# Create Homework Projects with GUID prefix.
# When FROM_JENKINS=true then project ownership is set to USER
# Set FROM_JENKINS=false for testing outside of the Grading Jenkins
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID USER FROM_JENKINS"
    exit 1
fi

GUID=$1
USER=$2
FROM_JENKINS=$3

echo "Creating Demo Projects for GUID=${GUID} and USER=${USER}"
oc new-project ${GUID}-jenkins    --display-name="${GUID} Jenkins"
oc new-project ${GUID}-tasks-dev  --display-name="${GUID} Tasks Development"
oc new-project ${GUID}-tasks-prod --display-name="${GUID} Tasks Production"
oc new-project ${GUID}-sonarqube --display-name="${GUID} Tasks SonarQube"
oc new-project ${GUID}-nexus --display-name="${GUID} Tasks Nexus"

if [ "$FROM_JENKINS" = "true" ]; then
  oc policy add-role-to-user admin ${USER} -n ${GUID}-jenkins
  oc policy add-role-to-user admin ${USER} -n ${GUID}-tasks-dev
  oc policy add-role-to-user admin ${USER} -n ${GUID}-tasks-prod

  oc annotate namespace ${GUID}-jenkins    openshift.io/requester=${USER} --overwrite
  oc annotate namespace ${GUID}-tasks-dev  openshift.io/requester=${USER} --overwrite
  oc annotate namespace ${GUID}-tasks-prod openshift.io/requester=${USER} --overwrite
fi

echo "****** Done setting up projects ********"
