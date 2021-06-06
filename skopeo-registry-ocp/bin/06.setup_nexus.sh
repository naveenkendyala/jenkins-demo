#!/bin/bash
# Delete all Homework Projects
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Deploying Nexus"
oc project $1-nexus
oc adm policy add-scc-to-user anyuid -z default
oc new-app sonatype/nexus3:3.21.2 --name=nexus --as-deployment-config=true
oc expose svc nexus
oc rollout pause dc nexus
oc patch dc nexus --patch='{ "spec": { "strategy": { "type": "Recreate" }}}'
oc patch dc nexus --patch='{ "spec": { "template": { "spec": { "securityContext": { "fsGroup": 2000 }}}}}'
oc set resources dc nexus --limits=memory=2Gi,cpu=2 --requests=memory=1Gi,cpu=500m
oc set volume dc/nexus --add --overwrite --name=nexus-volume-1 --mount-path=/nexus-data/ --type persistentVolumeClaim --claim-name=nexus-pvc --claim-size=10Gi
oc set probe dc/nexus --liveness --failure-threshold 3 --initial-delay-seconds 60 -- echo ok
oc set probe dc/nexus --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8081/
oc rollout resume dc nexus

echo "Sleeping 300 seconds"
sleep 300
oc set deployment-hook dc/nexus --mid --volumes=nexus-volume-1 -- /bin/sh -c "echo nexus.scripts.allowCreation=true >./nexus-data/etc/nexus.properties"
oc rollout latest dc/nexus

echo "Sleeping 120 seconds"
sleep 120

# Execute the Nexus Settings
NEXUS_PASSWORD=$(oc rsh `oc get pods | grep nexus| grep Running| awk '{ print $1 }'` cat /nexus-data/admin.password)
echo $NEXUS_PASSWORD
curl -o setup_nexus3.sh -s https://raw.githubusercontent.com/redhat-gpte-devopsautomation/ocp_advanced_development_resources/master/nexus/setup_nexus3.sh
chmod +x setup_nexus3.sh
# $1: Nexus UserID, $2: Nexus Password, $3: Nexus URL
./setup_nexus3.sh admin $NEXUS_PASSWORD http://$(oc get route nexus --template='{{ .spec.host }}')
rm setup_nexus3.sh

oc expose dc nexus --port=5000 --name=nexus-registry
oc create route edge nexus-registry --service=nexus-registry --port=5000