# dina-local-deployment

This repository can deploy the DINA ecosystem for demonstration and/or test purpose.

# Requirements

* [Docker Engine](https://docs.docker.com/engine/install/) (tested with 20.10)
* [Docker-Compose](https://docs.docker.com/compose/) (tested with 2.6)
* Basic knowledge of Docker and Docker-Compose
* Minimum 12GB of RAM (for all modules)
* Local IP range must be available or updated

# Documentation

See complete [Documentation](https://aafc-bicoe.github.io/dina-local-deployment/).

# Setup

## Hosts file

The hosts file must be updated with the hostnames used in the local deployment. In Linux and Mac OSX, this is located at `/etc/hosts`. You should have the following entries, all pointing to the fixed IP of the Traefik container:

```
192.19.33.9 keycloak.local
192.19.33.9 dina.local
192.19.33.9 api.dina.local
```

## KeyCloak Provider Url

If you are running a local instance for testing purposes, you will not need to change the keycloak provider url.

The public facing URL of the keycloak provider is required for the keycloak container and the UI. This allows the UI and keycloak container to serve the appropriate keycloak urls for users in the browser. By default the URL provider is set to point to a local instance with Host `keycloak.local` and port `8080`. 

In the `.env` file you can set the `KEYCLOAK_EXTERNAL_URL` to point to the appropriate url.

```properties
KEYCLOAK_EXTERNAL_URL=http://My.Keycloak.Server:3239/auth
```

# How to run

Note: By default, a lot of modules won't be started. See Profiles Support section.

To run:

```
docker compose -f docker-compose.base.yml -f docker-compose.local.yml up
```

## Profiles Support

Profiles have been added to support the deployment of non-mandatory components defined under a specific profile keyword.

Available profiles:

* object_store_api
* search_api
* seqdb_api
* report_label_api
* kibana
* prometheus

Example command using profile:

```
$ COMPOSE_PROFILES=search_api docker compose -f docker-compose.base.yml -f docker-compose.local.yml up
```

It is also possible to use the `start_stop_dina.sh` script to enable/disable modules.

## Users and groups

After all the components have finished initializing, the UI will be available at `http://dina.local/`. By default, the following users are included:

* `admin`: admin in the realm but not in any groups
* `user`: in the `aafc`, `cnc` groups (no roles)
* `cnc-cm`: `collection-manager` in the `cnc` group
* `cnc-staff`: a `staff` in the `cnc` group
* `cnc-student`: a `student` in the `cnc` group
* `cnc-ro`: a `read-only` user in the `cnc` group
* `dina-admin`: a `dina-admin` in the `aafc` group

The password is the same as the username for all users.

# FAQ

Q. I get ```ERROR: for traefik  Cannot start service traefik: Address already in use``` on start

A. It's very likely that a previous run was not terminated correctly. Run the docker-compose `down` command again to make sure everything is stopped. If you continue to get the same error, try the following:

1. Stop and remove all containers.
```bash
docker-compose -f docker-compose.base.yml -f docker-compose.local.yml down
```

2. Start the keycloak container only.
```bash
docker-compose -f docker-compose.base.yml -f docker-compose.local.yml up -d keycloak
```

3. Once keycloak is running, try starting the rest of the containers.
```bash
docker-compose -f docker-compose.base.yml -f docker-compose.local.yml up
```

These steps can also be followed when using the search api as well, just add the `-d keycloak` after the `up`.

# Persist dina-db and keycloak data between containers

An optional override file is provided to allow the dina-db and keycloak services to persist their volumes between containers.

```
docker-compose \
-f docker-compose.base.yml \
-f persistence-override/docker-compose.override.persistence.yml \
-f docker-compose.local.yml \
up -d
```
