#!/bin/sh

# start with a fresh .env
cat base.env > .env

# $1 = folder of the module , $2 Variable name used to define the path to main compose file
copyDockerComposeFiles()
{
    cp $1/local/docker-compose.yml.example $1/docker-compose.yml
    cp $1/local/*.env $1/
    echo "$2="./$1 >> .env
}

copyDockerComposeFiles object-store-api BASE_PATH_TO_OBJECT_STORE
copyDockerComposeFiles agent-api BASE_PATH_TO_AGENT
copyDockerComposeFiles dina-user-api BASE_PATH_TO_USER
