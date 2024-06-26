pipeline {
    agent any

    triggers {
        githubPush()
    }

    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                checkout([$class: 'GitSCM', branches: [[name: '*/main']], userRemoteConfigs: [[url: 'https://github.com/kmotyczynskagd/spring-petclinic.git']]])
            }
        }

        stage('Release project version') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'githubToken', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]){
                        sh "./gradlew release -Prelease.customUsername='$USERNAME' -Prelease.customPassword='$PASSWORD' -Prelease.disableChecks -Prelease.pushTagsOnly"
                        def projectVersion = sh(script: './gradlew currentVersion -q -Prelease.quiet', returnStdout: true).trim()
                        env.PROJECT_VERSION = projectVersion
                        echo "Project version is: $PROJECT_VERSION"
                    }
                }
            }
        }

        stage('Build docker image') {
            steps {
                script {
                    sh "docker build -t spring-petclinic:latest ."
                }
            }
        }

        stage('Tag docker image') {
            steps {
                script {
                    sh "docker tag spring-petclinic:latest localhost:8082/repository/spring-petclinic/spring-petclinic:$PROJECT_VERSION"
                }
            }
        }

        stage('Login into Nexus') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'nexusCreds', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]){
                        sh "docker login localhost:8082 -u $USERNAME -p $PASSWORD"
                    }
                }
            }
        }

        stage('Push docker image') {
            steps {
                script {
                    sh "docker push localhost:8082/repository/spring-petclinic/spring-petclinic:$PROJECT_VERSION"
                }
            }
        }

        stage('Update application on GCP instance group VMs') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'GCLOUD_CREDS', variable: 'GCLOUD_CREDS'), file(credentialsId: 'SSH_PRIV_KEY', variable: 'SSH_PRIV_KEY')]) {
                        sh'''
                        gcloud auth activate-service-account --key-file="$GCLOUD_CREDS"
                        CONTAINER_NAME="spring-petclinic"
                        CICD_VM_IP="$(gcloud compute instances describe kmotyczynska-cicd --zone europe-central2-c --format='value(networkInterfaces[0].networkIP)')"
                        for ip_address in $(gcloud compute instances list --zones europe-central2-c --filter="name ~ ^kmotyczynska-app" --format='value(networkInterfaces[0].networkIP)'); do
                            ssh kmotyczynska@${ip_address} -o StrictHostKeyChecking=no -i ${SSH_PRIV_KEY} "if sudo docker ps -a -q -f name=${CONTAINER_NAME} | grep -q .; then sudo docker stop ${CONTAINER_NAME} && sudo docker rm ${CONTAINER_NAME}; fi; sudo docker run -d --name ${CONTAINER_NAME} -e MYSQL_URL=${MYSQL_URL} -e MYSQL_USER=${MYSQL_USER} -e MYSQL_PASS=${MYSQL_PASS} -p 80:8080 \"${CICD_VM_IP}:8082/repository/spring-petclinic/spring-petclinic:${PROJECT_VERSION}\"";
                        done
                        '''
                    }
                }
            }
        }
    }
}
