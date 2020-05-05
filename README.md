# dina-local-deployment

Warning: still experimental

# Goal

Repository where we can easily start the DINA system or parts of it while reusing the deployment defined by the modules to ensure they are 
running the way it was defined. It also ensures module isolation since they will all keep their default network so module's internals won't be exposed 
to other modules.

# Setup

## Git Submodules

To get the different files from the different modules, [git-submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) are used. They are currently configured to
point to the `dev` branches.

When cloning the projet:

* `git submodule init` (init all submodules)
* `git submodule update --remote` (update all submodules)
* `git submodule foreach --recursive git checkout dev` (put all submodules on dev branch)  

## Setup script

`setup.sh` script is used to assemble the different docker-compose from the different modules.


# How to run

Note: first docker-compose file will represent the "root" of relative paths so `docker-compose.base.yml` should be used. 

To run:
`docker-compose -f docker-compose.base.yml -f object-store-api/docker-compose.yml -f docker-compose.local.yml up`
