## Hello World for Helm

A simple Flask hello world application deployed on a local k8s cluster with Helm v3.

## Pre-requisites

* `kind`: Preferred over [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) due to its performance and architecture. `kind` can be found here: https://github.com/kubernetes-sigs/kind
* `Helm 3`: Helm v3 can be found here: https://helm.sh/
* `kubectl`: Installation instructions available here: https://kubernetes.io/docs/tasks/tools/install-kubectl/

## Create a new k8s cluster and namepace

```bash
# Create the cluster
kind create cluster --name flask-hello-world

# Apply the mandatory ingress-nginx components
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml

# Expose the nginx service using NodePort
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/baremetal/service-nodeport.yaml

# Apply kind specific patches to forward the hostPorts to the ingress controller
kubectl patch deployments -n ingress-nginx nginx-ingress-controller -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx-ingress-controller","ports":[{"containerPort":80,"hostPort":80},{"containerPort":443,"hostPort":443}]}],"nodeSelector":{"ingress-ready":"true"},"tolerations":[{"key":"node-role.kubernetes.io/master","operator":"Equal","effect":"NoSchedule"}]}}}}'

# Finally, create the new namepsace
kubectl create ns flask-hello-world
```

## Build and deploy the Docker image your DockerHub

```bash
# Set your DockerHub username and password
export DOCKERHUB_USER="username"
export DOCKERHUB_PASSWORD="password"

# Push the image
make docker/push
```

### Deploy to k8s

```bash
make helm/deploy
```

### Access service locally

```bash
# Run proxy command generator
make proxy
```
