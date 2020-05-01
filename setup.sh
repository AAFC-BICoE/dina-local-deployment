#!/bin/sh

# start with a fresh .env
cat base.env > .env

# $1 = folder of the module
copyDockerComposeFiles()
{
    cp $1/local/docker-compose.yml.example $1/docker-compose.yml
    cp $1/local/*.env $1/
    # won't work with more than 1 module. Prefix it ?
    echo "PATH_FROM_COMPOSE="./$1 >> .env
}

copyDockerComposeFiles object-store-api
#copyDockerComposeFiles agent-api
