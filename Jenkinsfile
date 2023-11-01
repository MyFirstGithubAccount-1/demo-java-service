#!/usr/bin/env groovy
/*
 * Build Maven Modules
 */

  pipeline {
    
      //  agent { label 'cbc-aws-g3-agent' }
      agent { label 'cbc-aws-g3-agent-ops' }
      //   agent { label 'gce-node' }

      environment {
        MODULE = "demo-java-service"
        MODULE_ENV_NAME = 'dev'
        ECR_ENV_NAME = 'dev'
        ECR_REGION = 'us-east-1'
        PROJECT = 'cbc'
        VERSION = "${PROJECT}-${MODULE_ENV_NAME}"
        SONAR_HOST = 'https://sonarqube.cloudbees.com'
        JFROG_HOST = 'jfrog.demo.cbc.beescloud.com'
        HARBOR_HOST = 'registry.saas-dev.beescloud.com'
        SLACK_CHANNEL = '#team-cbc-jenkins-notification'
        AUTHOR = 'cbc-infra@cloudbees.com'
        VENDOR = 'CloudBees'
        BASE_BUILD_IMAGE = 'maven:3.8.7-eclipse-temurin-17'
        BASE_FINAL_IMAGE = 'eclipse-temurin:17-jammy'
      }

      options {
          disableConcurrentBuilds()
          skipStagesAfterUnstable()
          ansiColor('xterm')
      }

      triggers {
          githubPush()
      }

      stages {
        
        stage('Start') {
          steps {
            cleanWs()
            script {
              currentBuild.description = "${env.GIT_BRANCH} ${env.GIT_COMMIT}"
            }
          }
        }

        stage('Checkout') {
          steps {
            deleteDir()
            checkout scm
          }
        }

        stage('Pre-build') {
          steps {
            script {
              withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "aws_${ECR_ENV_NAME}_creds"]]) {
                ACCOUNT = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
                ECR_REPO_URI = sh(script: "echo ${ACCOUNT}.dkr.ecr.${env.ECR_REGION}.amazonaws.com/${env.PROJECT}/${env.MODULE}", returnStdout: true).trim()
                ECR_REPO_LOGIN = sh(script: "aws ecr get-login-password --region ${env.ECR_REGION} | docker login --username AWS --password-stdin $ECR_REPO_URI || true", returnStdout: true).trim()
                GIT_SHORT_HASH = env.GIT_COMMIT.take(7)
                GIT_URL = sh (script: 'git config remote.origin.url',returnStdout: true).trim()
                GIT_TAG = sh (script: "git describe --tags --always | tr -d '\n'", returnStdout: true).trim()
                env.TARGET = sh(script: "echo ${ECR_REPO_URI}:${VERSION}", returnStdout: true).trim()
                env.TARGET_GIT_TAG = sh (script: "echo ${ECR_REPO_URI}:${GIT_TAG}", returnStdout: true).trim()
                env.TARGET_GIT_SHORT_HASH = sh(script: "echo ${ECR_REPO_URI}:${GIT_SHORT_HASH}", returnStdout: true).trim()
                env.TARGET_JFROG = sh(script: "echo ${JFROG_HOST}/${env.PROJECT}/${env.MODULE}:${VERSION}", returnStdout: true).trim()
                env.TARGET_JFROG_GIT_SHORT_HASH = sh(script: "echo ${JFROG_HOST}/${env.PROJECT}/${env.MODULE}:${GIT_SHORT_HASH}", returnStdout: true).trim()
                env.TARGET_HARBOR = sh(script: "echo ${HARBOR_HOST}/${env.PROJECT}/${env.MODULE}:${VERSION}", returnStdout: true).trim()
                env.TARGET_HARBOR_GIT_SHORT_HASH = sh(script: "echo ${HARBOR_HOST}/${env.PROJECT}/${env.MODULE}:${GIT_SHORT_HASH}", returnStdout: true).trim()
              }
            }
          }
        }

        // stage('Git-TAG-Verify') {
        //   steps {
        //     script {
        //       if (GIT_TAG ==~ /^v[0-9]{1,4}\.[0-9]{1,4}\.[0-9]{1,4}((-SNAPSHOT)(-[0-9]{1,4})?)?/) {
        //         sh "set +x && echo -e '\033[0;35m Valid TAG :\033[0m \033[0;34m ${GIT_TAG} \033[0m'"
        //       }
        //       else {
        //         sh "set +x && echo -e '\033[31m ${GIT_TAG} is an invalid TAG...!!! The TAG should be like vX.Y.Z OR vX.Y.Z-SNAPSHOT or vX.Y.Z-SNAPSHOT-X, where X, Y and Z can be maximum 4 digits. Some examples follows. \033[0m \n \n\t- \033[32mv1.1.1\033[0m \n\t- \033[32mv12.345.6789 \033[0m \n\t- \033[32mv1.0.0-SNAPSHOT\033[0m \n\t- \033[32mv987.22.432-SNAPSHOT\033[0m \n\t- \033[32mv3.344.35-SNAPSHOT-5 \033[0m \n\t- \033[32mv111.222.333-SNAPSHOT-6666\033[0m \n\t' && exit 1"
        //       }
        //     }
        //   }
        // } 

        stage('Build') {
          steps {
            withEnv(['TARGET_GIT_TAG=' + TARGET_GIT_TAG, 'GIT_URL=' + GIT_URL, 'GIT_TAG=' + GIT_TAG, 'TARGET=' + TARGET]) {
              withCredentials([[
                  $class: 'AmazonWebServicesCredentialsBinding',
                  credentialsId: "aws_${ECR_ENV_NAME}_creds"],

                  [$class: 'StringBinding',
                  credentialsId: 'sonarqube_token',
                  variable: 'SONAR_LOGIN'],

                  [$class: 'FileBinding',
                  credentialsId: 'maven-settings-xml',
                  variable: 'SETTINGS_XML']]) {
              sh "mkdir -p .m2 || true"
              sh "cp $SETTINGS_XML .m2/settings.xml" 
              sh '''
                docker build --pull -t $TARGET . \
                    --label "org.opencontainers.image.created=`date -u +%Y-%m-%dT%H:%M:%SZ`" \
                    --label "org.opencontainers.image.authors=${AUTHOR}" \
                    --label "org.opencontainers.image.url=${TARGET_GIT_TAG}" \
                    --label "org.opencontainers.image.source=${GIT_URL}" \
                    --label "org.opencontainers.image.version=${GIT_TAG}" \
                    --label "org.opencontainers.image.revision=${GIT_COMMIT}" \
                    --label "org.opencontainers.image.ref.name=${MODULE}" \
                    --label "org.opencontainers.image.vendor=${VENDOR}" \
                    --label "com.cloudbees.cbc.baseimage.url=${BASE_FINAL_IMAGE}" \
                    --build-arg "PROJECT_KEY=${MODULE}" \
                    --build-arg "SONAR_HOST=${SONAR_HOST}" \
                    --build-arg "SONAR_LOGIN=${SONAR_LOGIN}" \
                    --build-arg "BASE_BUILD_IMAGE=${BASE_BUILD_IMAGE}" \
                    --build-arg "BASE_FINAL_IMAGE=${BASE_FINAL_IMAGE}"
                    '''  
              }
            }
          }
        }

        // stage('Copy-Artifacts') {
        //   steps {
        //     withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "aws_${ECR_ENV_NAME}_creds"]]) {
        //       script {
        //         sh '''
        //             ID=$(docker create $TARGET)
        //             echo ${ID}
        //             mkdir -p ./target || true
        //             docker cp ${ID}:/app ./target/
        //             docker rm ${ID}
        //             ls ./target/app || true
        //             '''
        //       }
        //     }
        //   }
        // }

        stage('ECR-Push') {
          steps {
            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "aws_${ECR_ENV_NAME}_creds"]]) {
              script {
                sh "docker tag $TARGET $TARGET_GIT_TAG"
                sh "docker tag $TARGET $TARGET_GIT_SHORT_HASH"
                sh "docker push $TARGET"
                sh "docker push $TARGET_GIT_TAG"
                sh "docker push $TARGET_GIT_SHORT_HASH"
              }
            }
          }
        }

        // stage('Deploy') {
        //   steps {
        //     build job: 'BuildJobs/compliance-hub-module-deploy', parameters: [
        //       string(name: 'VERSION',  value: "${VERSION}"),
        //       string(name: 'ENV_NAME',  value: "${MODULE_ENV_NAME}"),
        //       string(name: 'MODULE',  value: "${MODULE}")
        //       ], wait: false
        //   }
        // }

        // stage('JFrog-Push') {
        //   steps {
        //     withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jfrog_creds', usernameVariable: 'JFROG_USER_NAME', passwordVariable: 'JFROG_PASSWORD']]) {
        //       script {
        //         sh "docker login -u ${JFROG_USER_NAME} -p ${JFROG_PASSWORD} ${JFROG_HOST}"
        //         sh "docker tag $TARGET ${TARGET_JFROG}"
        //         sh "docker tag $TARGET ${TARGET_JFROG_GIT_SHORT_HASH}"
        //         sh "docker push ${TARGET_JFROG}"
        //       }
        //     }
        //   }
        // } 

        // stage('Harbor-Push') {
        //   when {
        //     expression {
        //       return pipelineParams.buildPushDeploy == 'true'
        //     }
        //   }
        //   steps {
        //     withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'harbor_creds', usernameVariable: 'HARBOR_USER_NAME', passwordVariable: 'HARBOR_PASSWORD']]) {
        //       script {
        //         sh "docker login -u ${HARBOR_USER_NAME} -p ${HARBOR_PASSWORD} ${HARBOR_HOST}"
        //         sh "docker tag $TARGET ${TARGET_HARBOR}"
        //         sh "docker tag $TARGET ${TARGET_HARBOR_GIT_SHORT_HASH}"
        //         sh "docker push ${TARGET_HARBOR}"
        //         sh "docker push ${TARGET_HARBOR_GIT_SHORT_HASH}"
        //       }
        //     }
        //   }
        // }


      }

    //   post {
    //     always {
    //       script {
    //         SLACK_COLOR_MAP = ['SUCCESS': '#2EB67D', 'FAILURE': '#E01E5A', 'UNSTABLE': '#ECB22E', 'ABORTED': '#A8B4BE']
    //       }

    //     slackSend (channel: "${SLACK_CHANNEL}",
    //               color: SLACK_COLOR_MAP[currentBuild.currentResult],
    //               message: "*Job*: _${env.JOB_NAME}_ \n *GIT_TAG*: `${env.GIT_BRANCH}` \n *GIT_COMMIT*: _${env.GIT_COMMIT}_ \n *Status*: `${currentBuild.currentResult}`\n *Console*: ${env.BUILD_URL}console \n ${currentBuild.getBuildCauses().shortDescription} ")
    //     }
    //   } 

  }
