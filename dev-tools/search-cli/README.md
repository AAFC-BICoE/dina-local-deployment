Provides a standalone (interactive) search-cli instance that connects to an already running local-deployment.

## How to use

```
docker-compose --env-file ../../.env -f docker-compose.search-cli-standalone.yml up
```

Connect to it:

```
docker attach search-cli-standalone
```

## Run multiple commands from a file

In the compose file uncomment the following section:

```
volumes:
- ./commandList.txt:/tmp/commandList.txt
```

Provide a file with a list of commands to run (here commandList.txt).

Use the `script` command in the container (once attached).
