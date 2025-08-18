Adapted from this blog post: https://some-natalie.dev/blog/kubernoodles-pt-5

```
NAMESPACE="arc-systems"
helm install arc \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
```

```sh
kubectl create namespace arc-runners
```
```sh
 kubectl create secret generic pre-defined-secret \
   --namespace=arc-runners \
   --from-literal=github_app_id=1738130 \
   --from-literal=github_app_installation_id=79528496 \
   --from-literal=github_app_private_key='-----BEGIN RSA PRIVATE KEY----- *********'
```

```sh
INSTALLATION_NAME="arc-runner-set"
NAMESPACE="arc-runners"
GITHUB_CONFIG_URL="https://github.com/<your_enterprise/org/repo>"
helm upgrade --install "${INSTALLATION_NAME}" \
    --namespace "${NAMESPACE}" \
    --create-namespace \
    --values gha-runner-scale-set.values.yml \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```



## Setup minio

```sh
helm repo add minio https://charts.min.io/
```

```sh
kubectl create secret generic minio-secret \
   --namespace=arc-runners \
   --from-literal=rootUser=root \
   --from-literal=rootPassword=<password>
```

```sh
kubectl label nodes tribe-ariel-ci1 minio=true
```

```sh
helm install "minio-sccache" minio/minio --namespace arc-runners --values minio.values.yml
```
