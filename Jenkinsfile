pipeline {
    agent any

    environment {
        DOCKER_USER    = 'lifegoeson34'
        IMAGE_TAG      = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
        KUBE_NAMESPACE = 'modami'
        DOCKER_BUILDKIT = '1'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '5', daysToKeepStr: '7'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {
        stage('Discover Services') {
            steps {
                script {
                    def raw = sh(script: "ls -d services/*/", returnStdout: true).trim()
                    env.SERVICES = raw.split('\n').collect { it.replaceAll('services/', '').replaceAll('/', '') }.join(',')
                    echo "Services to build: ${env.SERVICES}"
                }
            }
        }

        stage('Build & Push') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DH_USER',
                        passwordVariable: 'DH_PASS'
                    )]) {
                        sh 'echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin'
                    }

                    def jobs = [:]
                    env.SERVICES.split(',').each { svc ->
                        def serviceName = svc.trim()
                        jobs[serviceName] = { buildAndPush(serviceName) }
                    }
                    parallel jobs
                }
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                script {
                    withCredentials([file(credentialsId: 'kubeconfig-modami', variable: 'KUBECONFIG')]) {
                        env.SERVICES.split(',').each { svc ->
                            def serviceName = svc.trim()
                            sh """
                                kubectl rollout restart deployment/${serviceName} \
                                    -n ${KUBE_NAMESPACE} \
                                    --kubeconfig=\${KUBECONFIG} || true
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            sh '''
                docker logout || true
                docker system prune -af --volumes || true
                docker builder prune -af || true
                docker volume prune -f || true
            '''
            cleanWs(deleteDirs: true, disableDeferredWipeout: true)
        }
        success {
            echo "Pipeline SUCCESS — tag: ${IMAGE_TAG}"
        }
        failure {
            echo "Pipeline FAILED — check stage logs above"
        }
    }
}

// ─── helpers ───────────────────────────────────────────────────────────────

def buildAndPush(String serviceName) {
    def image = "${env.DOCKER_USER}/${serviceName}"
    def tag   = env.IMAGE_TAG

    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
        echo "[${serviceName}] building image ${image}:${tag}"

        sh """
            docker build \
                --pull \
                --cache-from ${image}:latest \
                -t ${image}:${tag} \
                -t ${image}:latest \
                services/${serviceName}

            docker push ${image}:${tag}
            docker push ${image}:latest

            docker rmi ${image}:${tag} ${image}:latest || true
        """

        echo "[${serviceName}] pushed ${image}:${tag} ✓"
    }
}
