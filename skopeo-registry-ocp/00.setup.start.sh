#!/bin/bash
# Create Homework Projects with GUID prefix.
# When FROM_JENKINS=true then project ownership is set to USER
# Set FROM_JENKINS=false for testing outside of the Grading Jenkins
# Example is below
# 

if [ "$#" -ne 2 ]; then
    echo "## Pass $GIT_USER GIT_PASSWORD ****"
    echo "#1 Ensure you have authenticated yourself with the OpenShift Cluster ****"
    echo "#2 Ensure that you have the image pull secret in the current folder ****"
    echo "   12821208-nkendyal-pull-secret.yml"
    echo "   Check here on how to download : https://access.redhat.com/terms-based-registry/#/accounts"
    echo "#2 Update the variables in this file ****"
    exit 1
fi

GUID=demo
USER=opentlc-mgr
FROM_JENKINS=false

GIT_REPO=https://github.com/naveenkendyala/jenkins-demo.git
GIT_USER=$1
GIT_PASSWORD=$2

JENKINS_FILE_PATH=skopeo-registry-ocp/openshift-tasks/Jenkinsfile
#Example is shown below. Use the URL from the OpenShift console
CLUSTER_API=https://api.cluster-9c33.9c33.example.opentlc.com:6443


#Manifests are needed only when you want to use this script for any other project
#bin/01.setup_manifests.sh $GUID $GIT_REPO $JENKINS_FILE_PATH

bin/02.setup_projects.sh $GUID $USER $FROM_JENKINS
echo "------------------------------------------------------------------------------------------------------------------------"
#bin/03.setup_dev.sh $GUID
echo "------------------------------------------------------------------------------------------------------------------------"
#bin/04.setup_prod.sh $GUID
echo "------------------------------------------------------------------------------------------------------------------------"
#bin/05.setup_sonarqube.sh $GUID
echo "------------------------------------------------------------------------------------------------------------------------"
#bin/06.setup_nexus.sh $GUID
echo "------------------------------------------------------------------------------------------------------------------------"
bin/07.setup_jenkins_persistent.sh $GUID $GIT_USER $GIT_PASSWORD
echo "------------------------------------------------------------------------------------------------------------------------"