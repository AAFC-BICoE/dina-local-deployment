# dina-local-deployment

This project helps to start the DINA ecosystem with Keycloak using Docker Compose.

Tested with [Docker-Compose](https://docs.docker.com/compose/) 1.28, Ubuntu hosts and 12GB of RAM.

For development setup see [dina-dev](https://github.com/AAFC-BICoE/dina-dev) (private repo).

# Goal

Repository where we can start the DINA system for demonstration and/or test purpose.

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

To run:

```
docker-compose \
-f docker-compose.base.yml \
-f docker-compose.local.yml up
```
Note: By default, a lot of modules won't be started. See Profiles Support section.

## Profiles Support

Profiles have been added to support the deployment of non-mandatory components defined under a specific profile keyword (requires Docker-Compose >= 1.28.0).

Available profiles:

* object_store_api
* search_api
* seqdb_api
 
Example command using profile:

```
docker-compose --profile search_api -f docker-compose.base.yml -f docker-compose.local.yml up
```

## Users and groups

After all the components have finished initializing, the UI will be available at `http://dina.local/`. By default, the following users are included:

* `admin`: admin in the realm but not in any groups
* `user`: in the `aafc`, `cnc` groups (no roles)
* `cnc-cm`: `collection-manager` in the `cnc` group
* `cnc-staff`: a `staff` in the `cnc` group
* `dina-admin`: a `dina-admin` in the `aafc` group

The password is the same as the username for all users.

# How to debug

`docker-compose -f docker-compose.base.yml -f object-store-api/docker-compose.yml -f docker-compose.local.yml -f docker-compose.dev.yml up`

This will expose `localhost:5005` for remote debugging.

Note: docker-compose.dev.yml currently includes the object-store only. When new modules will be available this will probably be changed to be per module (e.g. docker-compose-object-store-api.dev.yml) to avoid starting all modules in debug mode.

# Documentation
* DINA [Keycloak testing](docs/keycloak.md)

