pipeline {
    agent any
    
    stages {
        stage('Scan Dockerfile') {
            steps {
                sh 'trivy config --exit-code 1 --severity CRITICAL,HIGH,MEDIUM .'
            }
        }

        stage('Build images') {
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

        stage('Pull image and Create container') {
            when {
                expression {
                    currentBuild.result == null || currentBuild.result == 'SUCCESS'
                }
            }
            steps {
                sh 'ansible-playbook -i inventory playbook.yml'
            }
        }
    }
}
