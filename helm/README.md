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

### Local certificates

Local certificates are required to run the application locally without having warnings from the browser.

If you already have the certificates from the docker-compose based local deployment, you can copy them.
Otherwise, see [instructions](https://aafc-bicoe.github.io/dina-local-deployment/#_local_certificates) and make sure to install them in `helm/config/certs`.

### hosts file

Edit etc/hosts file map ingress ip to addresses used:

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

### Passwords

Unless a password is explicitly provided in `values.yaml`, the chart will automaticly generate them and store them in a secret for future run. The default behavior is auto-generating the secrets and the passwords in global.environment.config block are left empty for that purpose. Should the user prefer to provide static passwords, that is where they should do it.

To get an auto-generated password (e.g. login in Keycloak admin console) : `kubectl get secrets keycloak-admin-secret -o json | jq .data.password | tr -d '"' | base64 -d` or `kubectl get secret keycloak-admin-secret -o jsonpath="{.data.password}" | base64 --decode`

### Deploy chart

From dina-local-deployment root:

`helm install dina-helm ./helm -f helm/values.yaml`

To redeploy the chart:

`helm upgrade dina-helm ./helm -f helm/values.yaml`

To remove the chart: 

`helm uninstall dina-helm`


### Deploying chart in OKD environment or alternative environments.

From dina-local-deployment root

`helm install dina-helm ./helm -f helm/values.yaml -f helm/<additional_value_injection.yaml>`

In Helm, when multiple injection values are passed as arguments, such as in this example, the rightmost file takes precedence in overriding previously injected values.

Note that if you require additional alternative override values it is always preferrable to define it in a new injection file.

### Building Local Images

In order to use local images with MiniKube you will need to run the following command:

`minikube image load object-store-api:dev`

Then it can be changed in the values.yaml file:

```
services:
  objectstoreapi:
    image: dina-db-init-container:dev
```

### Mounting Directories

The following minikube command will allow you to mount a directory to a container inside of your local cluster:

`minikube mount <source directory>:<target directory>`

This command will need to stay running in it's own terminal.

Then the volume will need to be defined in the `helm/templates/deployments` or `helm/templates/jobs` yaml file for the specific container. 

The example below is for the `helm/templates/jobs/db-restore.yaml` to mount a SQL dump for restoring the database. You will first need to add it to the `volumeMounts:` and `volumes:` sections:

```
minikube mount ./sql-dump:/opt/pgrestore/data/
```

```
          volumeMounts:
            - name: sql-dump-volume
              mountPath: /opt/pgrestore/data/
```

```
      volumes:
        - name: sql-dump-volume
          hostPath:
            path: "/opt/pgrestore/data/"
```
