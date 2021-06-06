#!/bin/bash
# Delete all Homework Projects
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Deploying SonarQube"
oc project $1-sonarqube
#oc new-app --template=postgresql-ephemeral --param POSTGRESQL_USER=sonar --param POSTGRESQL_PASSWORD=sonar --param POSTGRESQL_DATABASE=sonar --param VOLUME_CAPACITY=4Gi --labels=app=sonarqube_db
#oc set volume rc/pos --add --overwrite --name=v1 --type=persistentVolumeClaim
oc new-app --template=postgresql-ephemeral --param POSTGRESQL_USER=sonar --param POSTGRESQL_PASSWORD=sonar --param POSTGRESQL_DATABASE=sonar --labels=app=sonarqube_db --as-deployment-config=true

echo "Sleeping 60 seconds"
sleep 60
oc new-app --docker-image=quay.io/gpte-devops-automation/sonarqube:7.9.1 --env=SONARQUBE_JDBC_USERNAME=sonar --env=SONARQUBE_JDBC_PASSWORD=sonar --env=SONARQUBE_JDBC_URL=jdbc:postgresql://postgresql/sonar --labels=app=sonarqube  --as-deployment-config=true
oc rollout pause dc sonarqube
oc expose service sonarqube
#oc set volume dc/sonarqube --add --overwrite --name=sonarqube-volume-1 --mount-path=/opt/sonarqube/data/ --type persistentVolumeClaim --claim-name=sonarqube-pvc --claim-size=5Gi
oc set resources dc/sonarqube --limits=memory=3Gi,cpu=2 --requests=memory=2Gi,cpu=1
oc patch dc sonarqube --patch='{ "spec": { "strategy": { "type": "Recreate" }}}'
oc set probe dc/sonarqube --liveness --failure-threshold 3 --initial-delay-seconds 40 --get-url=http://:9000/about
oc set probe dc/sonarqube --readiness --failure-threshold 3 --initial-delay-seconds 20 --get-url=http://:9000/about
oc patch dc/sonarqube --type=merge -p '{"spec": {"template": {"metadata": {"labels": {"tuned.openshift.io/elasticsearch": "true"}}}}}'
oc rollout resume dc sonarqube
echo "SonarQube Setup Complete"

