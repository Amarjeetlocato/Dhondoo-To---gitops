# 🚀 Dhondoo Platform GitOps

This repository manages the declarative infrastructure, microservices deployment, secrets management, monitoring, and automated continuous delivery for the **Dhondoo Platform** using **GitOps** principles with **Argo CD**, **Helm**, **Kustomize**, **Strimzi Kafka**, **Bitnami Sealed Secrets**, and **Prometheus / Alertmanager**.

---

## 🏛️ Architecture & Core Components

```
                    ┌─────────────────────────┐
                    │ GitHub Actions CI Pipeline│
                    └────────────┬────────────┘
                                 │ Event Trigger / Tag Update
                                 ▼
                    ┌─────────────────────────┐
                    │ GitOps Repository (Main) │
                    └────────────┬────────────┘
                                 │
                                 ▼
                    ┌─────────────────────────┐
                    │    Argo CD Bootstrap    │
                    │   (bootstrap/root-app)  │
                    └────────────┬────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         ▼                       ▼                       ▼
┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│  Infrastructure  │   │   Kafka Cluster  │   │  Platform Apps   │
│(Namespaces/Quota)│   │  (Strimzi CRDs)  │   │  (Microservices) │
└──────────────────┘   └──────────────────┘   └──────────────────┘
```

1. **App-of-Apps Bootstrap Pattern:** The root application (`bootstrap/root-app.yaml`) automatically syncs the `applications/` manifests into Argo CD.
2. **Reusable Parent Helm Chart (`helm/common`):** Microservices extend `dhondoo-common-1.0.0.tgz`, reducing boilerplate across services.
3. **Multi-Environment Promotion:** Strict environment segregation across `development`, `staging`, and `production` (`environments/` directory).
4. **Zero-Trust Network Policies & Quotas:** Enforces explicit namespace traffic rules and resource bounds (`infrastructure/namespaces/`).
5. **Sealed Secrets Pipeline:** Sensitive configurations are encrypted using `kubeseal` and safely committed into Git (`infrastructure/namespaces/secrets/`).
6. **Prometheus & Alertmanager Gmail Notifications:** Automated email alerts for pod restarts, high CPU/memory usage (>85%), and deployment unavailability.

---

## 📂 Repository Structure

```
.
├── bootstrap/                        # Argo CD Root Application (Entry point)
│   └── root-app.yaml
├── applications/                     # Argo CD Application manifests
│   ├── platform.yaml
│   ├── infrastructure.yaml
│   ├── kafka-operator.yaml
│   ├── kafka-cluster.yaml
│   ├── monitoring.yaml
│   └── sealed-secrets.yaml
├── helm/                             # Helm Charts
│   ├── common/                       # Parent reusable Helm Chart (v1.0.0)
│   ├── gateway/                      # API Gateway
│   ├── user-service/                 # User & Auth Service
│   ├── chat-service/                 # Chat Service
│   ├── shop-service/                 # Shop Service
│   ├── order-service/                # Order Service
│   ├── notification-service/         # Notification Service
│   ├── superuser-service/            # Admin Service
│   ├── service-registry/             # Eureka Registry
│   ├── mysql/                        # Database Chart
│   └── monitoring/                   # Prometheus & Alertmanager Chart
├── environments/                     # Environment Overrides
│   ├── development/                  # Dev values & Argo CD application manifests
│   ├── staging/                      # Staging values & Argo CD application manifests
│   └── production/                   # Prod values (HPA, PDB, Anti-Affinity, 3 Replicas)
├── infrastructure/                   # Core Cluster Infrastructure
│   ├── kafka/                        # Strimzi Kafka, Nodepools, Topics
│   ├── monitoring/                   # PrometheusRules, Grafana, Alertmanager Gmail
│   └── namespaces/                   # Namespaces, NetworkPolicies, Quotas, Secrets, ConfigMaps
└── .github/workflows/                # CI/CD Workflows
    ├── gitops-sync.yml               # Automated Image Sync on release
    ├── sealed-secrets.yml            # Automated Secret Sealing Workflow
    ├── production-validation.yml     # Helm template & manifest dry-run tests
    ├── helm-lint.yml                 # Helm chart linting
    ├── helm-template.yml             # Helm rendering tests
    ├── kustomize.yml                 # Kustomize validation
    └── pull-request-validation.yml   # PR safety checks
```

---

## 🔒 Secrets Management Pipeline

1. Add raw secrets in **GitHub Repository Settings -> Secrets and Variables -> Actions**.
2. Run the **Sealed Secrets** workflow (`.github/workflows/sealed-secrets.yml`) via `workflow_dispatch`.
3. The workflow uses `kubeseal` and the cluster's public certificate (`SEALED_SECRETS_CERT`) to encrypt the secrets into `SealedSecret` CRDs in `infrastructure/namespaces/secrets/`.
4. Argo CD deploys the encrypted `SealedSecret` objects to the Kubernetes cluster.
5. The **Bitnami Sealed Secrets Controller** inside the cluster decrypts them into standard Kubernetes `Secret` objects.

---

## 📧 Monitoring & Email Alerting

Prometheus rules (`platform-prometheusrule.yaml`) continuously evaluate metrics in the `platform` namespace and trigger email alerts via Alertmanager (`alertmanager-gmail-config.yaml`):

* **`DhondooDeploymentUnavailable` (Critical):** Triggers when desired pod replicas are unavailable for > 10 min.
* **`DhondooPodCrashLooping` (Critical):** Triggers when a pod restarts > 3 times in 15 min.
* **`DhondooHighCPU` / `DhondooHighMemory` (Warning):** Triggers when CPU or RAM usage exceeds **85%** of limits for 10 min.
* **`DhondooJVMHighHeap` (Warning):** Triggers when Java JVM Heap memory exceeds **85%** for 10 min.

---

## 🛠️ Developer Guide

### Adding a New Microservice

1. **Helm Chart:** Create `helm/<service-name>/` with `Chart.yaml`, `values.yaml`, and `templates/all.yaml` calling `dhondoo` parent templates.
2. **Environment Overrides:** Add `environments/<env>/values/<service-name>-values.yaml` for `development`, `staging`, and `production`.
3. **Argo CD App:** Create `environments/<env>/applications/<service-name>.yaml` and register it in `environments/<env>/applications/kustomization.yaml`.
4. **ConfigMap & Secret:** Add `infrastructure/namespaces/configmaps/<service-name>-config.yaml` and `infrastructure/namespaces/secrets/<service-name>-secret.yaml`, then register them in their respective `kustomization.yaml` files.
5. **Gateway Routing:** Update `infrastructure/namespaces/configmaps/gateway-config.yaml` with the new route predicate.

### Removing a Microservice

1. Remove `<service-name>.yaml` from `environments/*/applications/kustomization.yaml` and delete the application manifests. *(Argo CD auto-pruning will gracefully delete the deployed pods from the cluster)*.
2. Delete `environments/*/values/<service-name>-values.yaml`.
3. Delete `helm/<service-name>/`.
4. Delete corresponding ConfigMap, Secret, and Gateway route entries.
