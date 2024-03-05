pipeline {
    agent any
    
    stages {
        stage('Checkstyle') {
            when { 
                branch 'feature/*'
            }
            steps {
                sh './gradlew checkstyleMain checkstyleTest'
                archiveArtifacts artifacts: 'build/reports/checkstyle/main.html', fingerprint: true
            }
        }

        stage('Test') {
            when { 
                branch 'feature/*'
            }
            steps {
                sh './gradlew test'
            }
        }

        stage('Build') {
            when { 
                branch 'feature/*'
            }
            steps {
                sh './gradlew build -x test'
            }
        }
        
        stage('Create Docker Image') {
            when {
                anyOf {
                    branch 'main'
                    branch 'feature/*'
                }
            }
            environment {
                DOCKER_TAG = "mr" 
            }
            steps {
                script {
                    if (env.BRANCH_NAME == "main"){
                        DOCKER_TAG = "main"
                    }
                }
                sh '''
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
