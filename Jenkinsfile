pipeline {
    agent {
        label 'ansible-server'
    }
    environment {
        DOCKERHUB_CREDENTIALS = credentials('DockerHub')
        DOCKER_IMAGE = '$JOB_NAME:v1.$BUILD_ID'
        DOCKER_IMAGE_LATEST = '$JOB_NAME:latest'
    }
    stages {
        

        stage('Scan Dockerfile') {
            steps {
                sh 'trivy config --exit-code 1 --severity CRITICAL,HIGH,MEDIUM .'
            }
        }

        stage('Build images && Push to docker') {
            steps { 
                sh 'docker build -t DOCKER_IMAGE .'
                sh 'docker tag DOCKER_IMAGE kienkt/DOCKER_IMAGE'
                sh 'docker tag DOCKER_IMAGE kienkt/DOCKER_IMAGE_LATEST'
            }
        }

        stage('Scan images by Trivy') {
            steps {
                sh 'trivy image --exit-code 1 --severity CRITICAL,HIGH kienkt/DOCKER_IMAGE'
                sh 'trivy image --exit-code 1 --severity CRITICAL,HIGH kienkt/DOCKER_IMAGE_LATEST'
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
                sh 'docker push kienkt/DOCKER_IMAGE'
                sh 'docker push kienkt/DOCKER_IMAGE_LATEST'
                sh 'docker rmi DOCKER_IMAGE kienkt/DOCKER_IMAGE kienkt/DOCKER_IMAGE_LATEST'
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
