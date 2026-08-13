# infrastructure/monitoring/README.md

# Dhondoo Monitoring

Phase 5 monitoring provides:

- Pod restart detection
- Pod readiness monitoring
- Deployment availability monitoring
- CPU monitoring
- Memory monitoring
- JVM heap monitoring
- Spring Boot Prometheus metrics
- Kubernetes metadata labels

Monitoring namespace:

    monitoring

Application namespace:

    platform

Prometheus scrape endpoint:

    /actuator/prometheus

Scrape interval:

    30 seconds

The platform services must expose:

    /actuator/prometheus

before ServiceMonitor metrics can be collected.

Required monitoring stack:

    Prometheus Operator
    Prometheus
    Alertmanager
    Grafana

The ServiceMonitor and PrometheusRule resources in this directory
assume the Prometheus Operator CRDs are installed.

Phase 5 does not guarantee that a cluster can never fail.
It provides detection and alerting so failures are detected quickly.