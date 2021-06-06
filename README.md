= OpenShift 4 Jenkins Pipeline Demo

== About this demo application

=== This pipeline 

1. Pulls a sample java code from the source code repository
2. Builds the WAR file
3. Mimics unit testing
4. Performs code quality check and pushes the results to SonarQube
5. Pushes the build artifacts to Nexus
6. Builds the image and pushes it to Openshift's internal registry
7. Deploys the applications to Dev (namespace)
8. Mimics Integration Testing
9. Pushes the image from Openshift's internal registry to Nexus' container registry
10. Deploy the application to production (namespace) in a blue/green deployment
11. Waits for user approval before switching the route

=== Note: All the dependencies of this demo run in containers
- SonarQube
- Nexus Artifact Repo
- Nexus Container Registry
- Jenkins


=== Before you run this pipeline replace all the parameters enclosed between %% and %% with appropriate values. The files include
- bin/setup_jenkins.sh
- manifests/tasks-pipeline.yml
- openshift-tasks/Jenkinsfile
- openshift-tasks/nexus_settings.xml