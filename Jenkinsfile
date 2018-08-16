/*
Copyright 2018 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

// The declarative agent is defined in yaml.  It was previously possible to
// define containerTemplate but that has been deprecated in favor of the yaml
// format
// Reference: https://github.com/jenkinsci/kubernetes-plugin
pipeline {
  agent {
    kubernetes {
      label 'k8s-infra'
      defaultContainer 'jnlp'
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: build-node
spec:
  containers:
  - name: k8s-node-network-policy
    image: gcr.io/pso-helmsman-cicd/jenkins-k8s-node:1.0.1
    imagePullPolicy: Always
    command:
    - cat
    tty: true
    volumeMounts:
    # Mount the docker.sock file so we can communicate wth the local docker
    # daemon
    - name: docker-sock-volume
      mountPath: /var/run/docker.sock
    # Mount the local docker binary
    - name: docker-bin-volume
      mountPath: /usr/bin/docker
    # Mount the dev service account key
    - name: dev-key
      mountPath: /home/jenkins/dev
  volumes:
  - name: docker-sock-volume
    hostPath:
      path: /var/run/docker.sock
  - name: docker-bin-volume
    hostPath:
      path: /usr/bin/docker
  # Create a volume that contains the dev json key that was saved as a secret
  - name: dev-key
    secret:
      secretName: jenkins-deploy-dev-infra
"""
    }
  }


  stages {

    // stage('Setup access') {
    //   steps {
    //    container('k8s-node') {
    //       script {
    //             // env.CLUSTER_ZONE will need to be updated to match the
    //             // ZONE in the jenkins.propeties file
    //             env.CLUSTER_ZONE = "${CLUSTER_ZONE}"
    //             // env.PROJECT_ID will need to be updated to match your GCP
    //             // development project id
    //             env.PROJECT_ID = "${PROJECT_ID}"
    //             env.REGION = "${REGION}"
    //             //env.CLUSTER_NAME = "${CLUSTER_NAME}"
    //             env.KEYFILE = "/home/jenkins/dev/jenkins-deploy-dev-infra.json"
    //         }
    //       // Setup gcloud service account access
    //       sh "gcloud auth activate-service-account --key-file=${env.KEYFILE}"
    //       sh "gcloud config set compute/zone ${env.CLUSTER_ZONE}"
    //       sh "gcloud config set core/project ${env.PROJECT_ID}"
    //       sh "gcloud config set container/cluster ${env.CLUSTER_NAME}"
    //       sh "gcloud config set compute/region ${env.REGION}"
    //      }
    //     }
    // }
    stage('Setup access') {
      steps {
        container('k8s-node-network-policy') {
          script {
                env.PROJECT_ID = "${PROJECT_ID}"
                env.KEYFILE = "/home/jenkins/dev/jenkins-deploy-dev-infra.json"
            }
          // Setup gcloud service account access
          sh "gcloud auth activate-service-account --key-file=${env.KEYFILE}"
          sh "gcloud config set core/project ${env.PROJECT_ID}"
         }
        }
    }

    stage('linter') {
      steps {
        container('k8s-node-network-policy') {
          // Checkout code from repository
          checkout scm
          sh "make all"
        }
      }
    }

    stage('create') {
      steps {
        container('k8s-node-network-policy') {
          sh "make create"
        }
      }
    }

    stage('validate') {
      steps {
        container('k8s-node-network-policy') {
          script {
            for (int i = 0; i < 3; i++) {
               sh "make validate"
            }
          }
        }
      }
    }

    stage('delete') {
      steps {
        container('k8s-node-network-policy') {
          sh "make delete"
        }
      }
    }

  }

  post {
    always {
      container('k8s-node-network-policy') {
        sh 'gcloud auth revoke'
      }
    }
  }
}
