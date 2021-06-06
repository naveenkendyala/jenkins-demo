
# Set the variables
GUID=demo

#Change the project to Nexus
#oc project $GUID-nexus

# Get the Nexus Details from the running Pods
NEXUS_USER=admin
NEXUS_PASSWORD=$(oc rsh `oc get pods -n $GUID-nexus | grep nexus| grep Running| awk '{ print $1 }'` cat /nexus-data/admin.password)
NEXUS_URL=
NEXUS_DOCKER_REPO_URL=

echo $NEXUS_USER
echo $NEXUS_PASSWORD
echo $NEXUS_URL
echo $NEXUS_DOCKER_REPO_URL

# Make a copy of the Nexus Template
# Update the Nexus Settings in the copy

# Make a copy of the Jenkinsfile Template
# Update the SonarQube & Nexus Settings in the Jenkinsfile
