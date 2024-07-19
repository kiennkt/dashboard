pipeline {
    agent {
        label 'ansible-server'
    }
    enviroment {
        DOCKERHUB_CREDENTIALS = credentials('DockerHub')
    }
    stages {
        

        stage('Scan Dockerfile') {
            steps {
                sh 'trivy config --exit-code 1 --severity CRITICAL,HIGH,MEDIUM .'
            }
        }

        stage('Build images && Push to docker') {
            steps { 
                sh 'docker build -t $JOB_NAME:v1.$BUILD_ID .'
                sh 'docker tag $JOB_NAME:v1.$BUILD_ID kienkt/$JOB_NAME:v1.$BUILD_ID'
                sh 'docker tag $JOB_NAME:v1.$BUILD_ID kienkt/$JOB_NAME:latest'
            }
        }

        stage('Scan images by Trivy') {
            steps {
                sh 'trivy image --exit-code 1 --severity CRITICAL,HIGH kienkt/$JOB_NAME:v1.$BUILD_ID'
                sh 'trivy image --exit-code 1 --severity CRITICAL,HIGH kienkt/$JOB_NAME:latest'
            }
        }

        stage('Docker Login') {
            steps {
                sh 'echo DOCKERHUB_CREDENTIALS_PSW'
                sh 'docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
            }
        }
        stage('Push to Docker hub') {
            when {
                expression {
                    currentBuild.result == null || currentBuild.result == 'SUCCESS'
                }
            }
            steps {
                sh 'docker push kienkt/$JOB_NAME:v1.$BUILD_ID'
                sh 'docker push kienkt/$JOB_NAME:latest'
                sh 'docker rmi $JOB_NAME:v1.$BUILD_ID kienkt/$JOB_NAME:v1.$BUILD_ID kienkt/$JOB_NAME:latest'
            }
        }

        stage('Manage node server to create container') {
            when {
                expression {
                    currentBuild.result == null || currentBuild.result == 'SUCCESS'
                }
            }
            steps {
                sh 'cd ~/ansible-jenkins/'
                sh 'ansible-playbook -i inventory.ini playbook_bak.yml'
            }
        }
    }
}
