# mockServer

## Replace search-ws with mockServer

To replace `search-ws` with `mockServer`. 

All we need to do is to enable the `mockServer` profile when running the `docker-compose up` command.

Example command of using the `mockServer` profile

```console
docker-compose --profile mockServer -f docker-compose.base.yml -f docker-compose.local.yml up
```

After running the command, mockServer will be exposed through port 1080.

To replace the `mockServer` with `search-ws`

We need to enable the `search_api` profile when running the `docker-compose up` command

```console
docker-compose --profile search_api -f docker-compose.base.yml -f docker-compose.local.yml up
```

## Reply to search-ws

Expectations are placed in the `initializerJson.json` file.

Example:

```console
curl http://localhost:1080/search/auto-complete?prefix=Jim&autoCompleteField=data.attributes.displayName&additionalField=data.attributes.aliases&indexName=dina_agent_index
```
Response:

```
[1] 19404
[2] 19405
[3] 19406
```