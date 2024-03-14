pipeline {
    agent any

    triggers {
        githubPush()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: '*/main']], userRemoteConfigs: [[url: 'https://github.com/kmotyczynskagd/spring-petclinic.git']]])
            }
        }

        stage('Get Project Version') {
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

        stage('Replace in project version dots to dashes') {
            steps {
                script {
                    env.PROJECT_VERSIONGCP = env.PROJECT_VERSION.replace(".", "-")
                    echo "Project version is: $PROJECT_VERSION"
                }
            }
        }

        stage('Update docker image on GCP instance group') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'GCLOUD_CREDS', variable: 'GCLOUD_CREDS')]) {
                        sh"""
                        gcloud auth activate-service-account --key-file='$GCLOUD_CREDS'
                        CONTAINER_NAME="spring-petclinic"
                        INSTANCES_IP_ADDRESSES=$(gcloud compute instances list --zones europe-central2-c --filter="name ~ ^kmotyczynska-app" --format='value(networkInterfaces[0].accessConfigs[0].natIP)')
                        docker stop ${CONTAINER_NAME} && docker rm ${CONTAINER_NAME}
                        docker run --name ${CONTAINER_NAME} "localhost:8082/repository/spring-petclinic/spring-petclinic:${PROJECT_VERSION}"
                        docker rmi "localhost:8082/repository/spring-petclinic/spring-petclinic:${PROJECT_VERSION}"
                        """
                    }
                }
            }
        }
    }
}
