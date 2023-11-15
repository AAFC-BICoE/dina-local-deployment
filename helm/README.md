## Pre-requisites

1. Helm
2. Minikube
3. Local certificates

## Installing Helm

```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

## Installing minikube

```
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```
 
# Starting minikube

```
minikube start --addons=ingress --cpus=4 --cni=flannel --install-addons=true --kubernetes-version=stable --memory=6g
```

Change the cpus and memory according to your local resources.

Note: This is a sample command. The important flags here are:
```
 --addons=ingress 
 --cni=flannel 
 --install-addons=true
```

Note:
Useful alias for running kubectl commands: `alias k="minikube kubectl --"`

## Deploying application

1. Local certificates

Local certificates are required to run the application locally without having warnings from the browser.

If you already have the certificates from the docker-compose based local deployment, you can copy them.
Otherwise, see [instructions](https://aafc-bicoe.github.io/dina-local-deployment/#_local_certificates) and make sure to install them in `helm/config/certs`.

2. Edit etc/hosts file map ingress ip to addresses used:

Get ingress ip:

```
minikube kubectl -- get nodes -o wide
```

Sample output:
```
NAME       STATUS   ROLES           AGE     VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
minikube   Ready    control-plane   4d18h   v1.27.4   192.168.49.2   <none>        Ubuntu 22.04.2 LTS   6.2.0-36-generic   docker://24.0.4
```
Ingress IP is listed under 'INTERNAL-IP'

In `/etc/hosts` file, add the following lines:
 
```
<INGRESS IP> dina.local
<INGRESS IP> keycloak.dina.local
```

3. Deploy chart (Once minikube is running):

From dina-local-deployment root:

`helm install dina-helm ./helm -f helm/values.yaml`
