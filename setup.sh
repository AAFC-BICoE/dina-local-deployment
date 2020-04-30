#!/bin/sh

rm .env

# $1 = folder, $2 environment variable prefix
copyDockerComposeFiles()
{
    cp $1/local/docker-compose.yml.example $1/docker-compose.yml
    cp $1/local/.env.example $1/.env
    echo $2"_ROOT_DIR="$1 >> .env
}

copyDockerComposeFiles object-store-api OS
#copyDockerComposeFiles agent-api

cat base.env >> .env
cat object-store-api/.env >> .env
