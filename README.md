# dina-local-deployment

This project help to start the DINA ecosystem with Keycloak using Docker Compose.

Tested with Docker-Compose 1.28 and Ubuntu hosts.

# Goal

Repository where we can easily start the DINA system for demonstration and/or test purpose.

# Setup

## Hosts file

The hosts file must be updated with the hostnames used in the local deployment. In Linux and Mac OSX, this is located at `/etc/hosts`, and in Windows it's `c:\windows\system32\drivers\etc\hosts`. You should have the following entries, all pointing to the fixed IP of the Traefik container:

`172.19.33.9 keycloak.local`
`172.19.33.9 dina.local`
`172.19.33.9 api.dina.local`

# How to run

To run:

```
docker-compose \
-f docker-compose.base.yml \
-f docker-compose.local.yml up
```

## Profiles Support

Profiles have been added to support the deployment of non-mandatory components defined under a specific profile keyword (requires Docker-Compsoe >= 1.28.0).

Available profiles:

* object_store_api
* search_api
 
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

