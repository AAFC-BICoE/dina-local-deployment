# dina-local-deployment

Warning: still very experimental

# Setup

## Setup script

setup script is used to assemble the different docker-compose from the different modules.  

## Git Submodules


# How to run

Note: first docker-compose file will represent the "root" of relative paths so docker-compose.base.yml should be used. 

docker-compose -f docker-compose.base.yml -f object-store-api/docker-compose.yml -f docker-compose.local.yml up

