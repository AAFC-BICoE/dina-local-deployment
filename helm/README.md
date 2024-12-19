## Pre-requisites

1. Helm
2. Minikube
3. Local certificates

## Installing Minikube and Helm

 * Minikube [instructions](https://aafc-bicoe.github.io/dina-local-deployment/#_minikube)
 * Helm [instructions](https://aafc-bicoe.github.io/dina-local-deployment/#_helm)

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

### Restore Database Dump and Reset User Credentials 

1. You will need a pgdump .sql file to restore from. This can be generated using the following command:

```bash
pg_dumpall -U <username> -h <hostname> -f dina_backup.sql
```

2. The restore must be encrypted in base64:

```bash
base64 dina_backup.sql > dina_backup.sql.b64 
```

3. Mount the file into the init-db container

See the Mounting Directories section below for instructions on mounting a folder. The examples in that section are specific to mounting a backup SQL file.

4. Create an override file in `/helm` to restore the database.

This file can be named `restore-db.yaml` for example:

```yaml
global:
  environment:
    config:
      db_init:
        restore_db: true
        db_dump_file_path: /opt/pgrestore/data/dina_backup.sql.b64
```

If the db-restore-job already exists, it will need to be deleted first:

```bash
kubectl delete job db-restore-job -n <your-namespace>
```

Install/Upgrade the new changes:

```bash
helm install dina-helm ./helm -f helm/values.yaml -f helm/restore-db.yaml
```

5. Optional - Reset the dina module user credentials

This file can be named `reset-dina-modules.yaml` for example.

```yaml
global:
  environment:
    config:
      db_init:
        reset_users: true
        dina_db: agent collection dina_user object_store seqdb loan_transaction export
```

The `dina_db` environment variable contains all of the modules that will be reset.

If the db-restore-job already exists, it will need to be deleted first:

```bash
kubectl delete job db-restore-job -n <your-namespace>
```

Install/Upgrade the new changes:

```bash
helm upgrade dina-helm ./helm -f helm/values.yaml -f helm/reset-dina-modules.yaml
```

6. Optional - Reset a generic user credentials (keycloak for example)

This file can be named `reset-keycloak.yaml` for example.

```yaml
global:
  environment:
    config:
      db_init:
        reset_users: true
        db_user: keycloak_user
        db_password: 
          valueFrom:
            secretKeyRef:
              name: dina-db-secret
              key: password
```

In the example above, this will use the `dina-db-secret` that was automatically generated.

If the db-restore-job already exists, it will need to be deleted first:

```bash
kubectl delete job db-restore-job -n <your-namespace>
```

Install/Upgrade the new changes:

```bash
helm upgrade dina-helm ./helm -f helm/values.yaml -f helm/reset-keycloak.yaml
```

7. Deploy as normal which will re-enable all the containers:

```bash
helm upgrade dina-helm ./helm -f helm/values.yaml
```

### Building Local Images

In order to use local images with MiniKube you will need to run the following command:

`minikube image load object-store-api:dev`

Then it can be changed in the values.yaml file:

```yaml
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

```bash
minikube mount ./sql-dump:/opt/pgrestore/data/
```

```yaml
          volumeMounts:
            - name: sql-dump-volume
              mountPath: /opt/pgrestore/data/
```

```yaml
      volumes:
        - name: sql-dump-volume
          hostPath:
            path: "/opt/pgrestore/data/"
```

### Helm Deployment particularities

* DINA modules all have their own init-container to initialize the database
* Passwords are auto-generated by Helm unless they are explicitly provided in `values.yaml`


