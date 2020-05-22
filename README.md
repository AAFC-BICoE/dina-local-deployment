# dina-local-deployment

* local deployment: start the DINA ecosystem with Keycloak using Docker Compose
* developement deployement (not available yet)

# Goal

Repository where we can easily start the DINA system or parts of it while reusing the deployment defined by the modules to ensure they are running the way it was defined. It also ensures module isolation since they will all keep their default network so module's internals won't be exposed to other modules.

# Setup

## Git Submodules

To get the different files from the different modules, [git-submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) are used. They are currently configured to
point to the `dev` branches.

When cloning the projet:

* `git submodule init` (init all submodules)
* `git submodule update --remote` (update all submodules)
* `git submodule foreach --recursive git checkout dev` (put all submodules on dev branch)

Note: git submodules are real git project. You can go in the folder and run any git command.

## Hosts file

An entry for Keycloak in your hosts file is required. In Linux and Mac OSX, this is located at `/etc/hosts`, and in Windows it's `c:\windows\system32\drivers\etc\hosts`. You should have an entry that matches the host name and IP in base.env:

`172.33.33.10 keycloak.local`

Additionally, you may also want to add entries for the other IP/hostname pairs in base.env:

- `172.33.33.11	dina.local` (DINA\_UI) will allow you to access the UI at `http://dina.local`; it uses port 80 so no port number is necessary in this case
- `172.33.33.12	api.dina.local` (OBJECT\_STORE\_API) will allow you to directly query the API (using CURL, Postman or other tools) at `api.dina.local:8080`

## Setup script

`setup.sh` script is used to assemble the different docker-compose from the different modules. The Docker Compose command of that project only works if the setup script is used to prepare all the required files.

# How to run

Note: first docker-compose file will represent the "root" of relative paths so `docker-compose.base.yml` should be used. 

To run:

`docker-compose -f docker-compose.base.yml -f object-store-api/docker-compose.yml -f docker-compose.local.yml up`

After all the components have finished initializing, the UI will be available at `http://localhost:2015`. By default, there are two users included: `user` and `admin`. The password is the same as the username for both.

# How to debug

`docker-compose -f docker-compose.base.yml -f object-store-api/docker-compose.yml -f docker-compose.local.yml -f docker-compose.dev.yml up`

This will expose `localhost:5005` for remote debugging.

Note: docker-compose.dev.yml currently includes the object-store only. When new modules will be available this will probably be changed to be per module (e.g. docker-compose-object-store-api.dev.yml) to avoid starting all modules in debug mode.

# Documentation
* DINA [Keycloak testing](docs/keycloak.md)
