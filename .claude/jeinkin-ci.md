You are a Senior DevOps Engineer and CI/CD Architect.

I am a backend engineer working with:

* Golang microservices (7 services)
* Docker (images pushed to DockerHub)
* Kubernetes (deployment target)
* Jenkins as CI system

My requirements:

1. Build 7 microservices in parallel
2. Each service is located under: /services/<service-name>
3. Each service:

   * build Go binary (linux, amd64)
   * build Docker image
   * push to DockerHub
4. Optimize for:

   * speed (parallel execution)
   * low disk usage (avoid disk full)
   * clean CI environment

Constraints:

* Jenkins may run on a single node OR Kubernetes agent
* Storage is limited (~200GB), so cleanup is critical
* Avoid Docker layer accumulation
* Avoid keeping artifacts locally
* Must be production-ready (not demo code)

Required features in Jenkinsfile:

* Parallel pipeline for all services
* Reusable function for building each service
* Proper Docker login using Jenkins credentials
* Tagging strategy (use build number and optionally commit SHA)
* Workspace cleanup after build
* Docker cleanup (remove images, prune system)
* Error handling (do not break entire pipeline unnecessarily)
* Logging (clear and readable)

Nice-to-have:

* Dynamic service list (instead of hardcoding)
* Ability to extend to Kubernetes agents later
* Optional caching strategy explanation (Go build / Docker)

Output format:

1. Full Jenkinsfile (declarative pipeline)
2. Short explanation of key design decisions
3. Optional improvements for scaling (Kubernetes, Kaniko, etc.)

Important:

* Keep code clean and production-grade
* Avoid unnecessary plugins
* Do NOT overcomplicate
* Focus on reliability and maintainability
