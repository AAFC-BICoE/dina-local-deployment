# mockServer

## Replace search-ws with mockServer

Replace docker-compose `search_api` profile with the `mockServer` profile.

Example command of using the `mockServer` profile

```console
docker-compose --profile mockServer -f docker-compose.base.yml -f docker-compose.local.yml up
```

mockServer will be exposed through port 1080

## Reply to search-ws

Expectations are placed in the `initializerJson.json` file.

Example:

```console
curl http://localhost:1080/search/auto-complete?prefix=Jim&autoCompleteField=data.attributes.displayName&additionalField=data.attributes.aliases&indexName=dina_agent_index
```

