pipeline {
    agent any
    
    stages {
        stage('Checkstyle') {
            when { 
                changeRequest target: 'main' 
            }
            steps {
                sh './gradlew checkstyleMain checkstyleTest'
                archiveArtifacts artifacts: 'build/reports/checkstyle/main.html', fingerprint: true
            }
        }

        stage('Test') {
            when { 
                changeRequest target: 'main' 
            }
            steps {
                sh './gradlew test'
            }
        }

        stage('Build') {
            when { 
                changeRequest target: 'main' 
            }
            steps {
                sh './gradlew build -x test'
            }
        }
        
        stage('Create Docker Image') {
            when {
                anyOf {
                    branch 'main'
                    changeRequest target: 'main'
                }
            }
            environment {
                DOCKER_TAG = "mr" 
            }
            steps {
                sh '''
                if [[ "${BRANCH_NAME}" == "main" ]]; then
                    DOCKER_TAG = "main"
                fi
                docker build -t "${DOCKER_TAG}:${GIT_COMMIT:0:7}" .
                docker push "${DOCKER_TAG}:${GIT_COMMIT:0:7}"
                '''
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
