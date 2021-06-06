
# Set the variables
GUID=demo

# Change the project to SonarQube & Get the Nexus Details from the running Pods
oc project $GUID-sonarqube
SONARQUBE_URL="http://$(oc get route/sonarqube --template='{{ .spec.host }}')"

# Change the project to Nexus & Get the Nexus Details from the running Pods
oc project $GUID-nexus
NEXUS_USER=admin
NEXUS_PASSWORD=$(oc rsh `oc get pods | grep nexus| grep Running| awk '{ print $1 }'` cat /nexus-data/admin.password)
NEXUS_URL="http://$(oc get route/nexus --template='{{ .spec.host }}')"
NEXUS_REGISTRY_URL=$(oc get route/nexus-registry --template='{{ .spec.host }}')

# Make a copy of the Nexus Template and replace the values
cp openshift-tasks/nexus.settings.template.xml openshift-tasks/nexus.settings.xml
gsed -i "s,NEXUS_URL,$NEXUS_URL,g" openshift-tasks/nexus.settings.xml
gsed -i "s/NEXUS_USER/$NEXUS_USER/g" openshift-tasks/nexus.settings.xml
gsed -i "s/NEXUS_PASSWORD/$NEXUS_PASSWORD/g" openshift-tasks/nexus.settings.xml

# Make a copy of the Jenkinsfile Template. Update SonarQube and Nexus values
cp openshift-tasks/Jenkinsfile.template openshift-tasks/Jenkinsfile
gsed -i "s,SONARQUBE_URL,$SONARQUBE_URL,g" openshift-tasks/Jenkinsfile
gsed -i "s,NEXUS_URL,$NEXUS_URL,g" openshift-tasks/Jenkinsfile
gsed -i "s,NEXUS_REGISTRY_URL,$NEXUS_REGISTRY_URL,g" openshift-tasks/Jenkinsfile
gsed -i "s/NEXUS_USER/$NEXUS_USER/g" openshift-tasks/Jenkinsfile
gsed -i "s/NEXUS_PASSWORD/$NEXUS_PASSWORD/g" openshift-tasks/Jenkinsfile

echo "Replacements complete. Ready for Checkin"

