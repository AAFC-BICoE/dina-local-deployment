# dina-local-deployment

* local deployment: start the DINA ecosystem with Keycloak using Docker Compose
* developement deployement (not available yet)

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

If you only want to start some services, you can create your own file based on docker-compose.local.yml and replace the command above with your file on top of the base file.


After all the components have finished initializing, the UI will be available at `http://dina.local/`. By default, the following users are included:

* `admin`: admin in the realm but not in any groups
* `user`: in the `aafc`, `cnc` groups (no roles)
* `cnc-cm`: `collection-manager` in the `cnc` group
* `cnc-staff`: a `staff` in the `cnc` group

The password is the same as the username for all users.

# How to debug

`docker-compose -f docker-compose.base.yml -f object-store-api/docker-compose.yml -f docker-compose.local.yml -f docker-compose.dev.yml up`

This will expose `localhost:5005` for remote debugging.

Note: docker-compose.dev.yml currently includes the object-store only. When new modules will be available this will probably be changed to be per module (e.g. docker-compose-object-store-api.dev.yml) to avoid starting all modules in debug mode.

# Documentation
* DINA [Keycloak testing](docs/keycloak.md)

