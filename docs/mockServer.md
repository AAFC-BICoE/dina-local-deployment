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
curl "http://localhost:1080/search/auto-complete?prefix=Jim&autoCompleteField=data.attributes.displayName&additionalField=data.attributes.aliases&indexName=dina_agent_index"
```
Expected response:

```json
{
    "internalResponse": {
        "numReducePhases": 1,
        "fragment": true
    },
    "scrollId": null,
    "totalShards": 1,
    "successfulShards": 1,
    "skippedShards": 0,
    "shardFailures": [],
    "clusters": {
        "total": 0,
        "successful": 0,
        "skipped": 0,
        "fragment": true
    },
    "numReducePhases": 1,
    "timedOut": false,
    "terminatedEarly": null,
    "failedShards": 0,
    "hits": {
        "hits": [],
        "totalHits": {
            "value": 0,
            "relation": "EQUAL_TO"
        },
        "maxScore": "NaN",
        "sortFields": null,
        "collapseField": null,
        "collapseValues": null,
        "fragment": true
    },
    "aggregations": null,
    "suggest": null,
    "took": {
        "seconds": 0,
        "days": 0,
        "hours": 0,
        "minutes": 0,
        "millis": 38,
        "micros": 38000,
        "microsFrac": 38000.0,
        "millisFrac": 38.0,
        "secondsFrac": 0.038,
        "minutesFrac": 6.333333333333333E-4,
        "hoursFrac": 1.0555555555555555E-5,
        "daysFrac": 4.398148148148148E-7,
        "nanos": 38000000,
        "stringRep": "38ms"
    },
    "profileResults": {},
    "fragment": false
}
```