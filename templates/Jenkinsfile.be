// ── CONFIG: chỉnh 3 dòng này theo từng service ───────────────────────────────
def IMAGE_NAME   = "be-modami-auth-service"   // DockerHub image name
def KUBE_DEPLOY  = "be-modami-auth-service"   // kubectl deployment name
def KUBE_NS      = "modami"                   // kubernetes namespace
def KUBE_CRED_ID = "kubeconfig-modami"        // Jenkins credential ID
// ─────────────────────────────────────────────────────────────────────────────

pipeline {
    agent any

    environment {
        DOCKER_USER     = 'lifegoeson34'
        IMAGE_TAG       = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
        DOCKER_HOST     = 'tcp://localhost:2375'
        DOCKER_BUILDKIT = '1'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '5', daysToKeepStr: '7'))
        timeout(time: 20, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DH_USER',
                    passwordVariable: 'DH_PASS'
                )]) {
                    sh """
                        echo "\$DH_PASS" | docker login -u "\$DH_USER" --password-stdin

                        docker build \\
                            --pull \\
                            --cache-from ${DOCKER_USER}/${IMAGE_NAME}:latest \\
                            -t ${DOCKER_USER}/${IMAGE_NAME}:${env.IMAGE_TAG} \\
                            -t ${DOCKER_USER}/${IMAGE_NAME}:latest \\
                            .

                        docker push ${DOCKER_USER}/${IMAGE_NAME}:${env.IMAGE_TAG}
                        docker push ${DOCKER_USER}/${IMAGE_NAME}:latest

                        docker rmi ${DOCKER_USER}/${IMAGE_NAME}:${env.IMAGE_TAG} \\
                                   ${DOCKER_USER}/${IMAGE_NAME}:latest || true
                    """
                }
            }
        }

        stage('Deploy') {
            when { branch 'master' }
            steps {
                withCredentials([file(credentialsId: "${KUBE_CRED_ID}", variable: 'KUBECONFIG')]) {
                    sh """
                        kubectl rollout restart deployment/${KUBE_DEPLOY} \\
                            -n ${KUBE_NS} \\
                            --kubeconfig=\${KUBECONFIG}
                        kubectl rollout status deployment/${KUBE_DEPLOY} \\
                            -n ${KUBE_NS} \\
                            --kubeconfig=\${KUBECONFIG} \\
                            --timeout=120s
                    """
                }
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
            sh 'docker system prune -af --volumes || true'
            sh 'docker builder prune -af || true'
            sh 'docker volume prune -f || true'
            cleanWs(deleteDirs: true, disableDeferredWipeout: true)
        }
        success {
            echo "SUCCESS: ${DOCKER_USER}/${IMAGE_NAME}:${env.IMAGE_TAG}"
        }
        failure {
            echo "FAILED: ${IMAGE_NAME} — check logs above"
        }
    }
}
