## Requirements ##
  * Python 3.7 or 3.8
  * Conda 4.8+ (optional)

## Initial Setup ##

1. Create and activate your virtual environment
* If you have conda installed:
```
conda create --name dina python=3.8
conda activate dina
```

* OR with venv (untested)
```
mkdir .env
python -m venv .env
source .env/bin/activate
```

2. Install requirements
```
python -m pip install -r requirements.txt
```

3. Make a copy of keycloak-config.yml.sample and make the appropriate updates to the new file.
```
cp keycloak-config.yml.sample keycloak-config.yml
```

## Run ##
```
python access_api_with_keycloak_token.py [-h] -u URL [-d DATA] [-f JSON_FILE] [-H HEADERS] [-X {GET,POST,PATCH,DELETE}]

  -h,   --help              show this help message and exit
  -u    --url URL           API URL of request
  -d    --data              Python string representation of a dictionary
  -f    --json_file         json filepath
  -H    --headers           Python dictionary, e.g. '{"Content-Type": "application/vnd.api+json", "Accept": "application/vnd.api+json"}'
  -X    --request           {get,post,patch,delete,GET,POST,PATCH,DELETE}. Default = GET
```
Usage examples:

Get: 
```
python access_api_with_keycloak_token.py --url http://api.dina.local/agent/api/v1/agent
```
Post:
```
python access_api_with_keycloak_token.py -X POST -url http://api.dina.local/agent/api/v1/agent -H '{"Content-Type": "application/vnd.api+json", "Accept": "application/vnd.api+json"}' --data '{"data": {"type": "agent", "attributes": {"displayName": "Samah Hassan", "email": "samah@email.com"}}}'
```

```
python access_api_with_keycloak_token.py --url http://api.dina.local/agent/api/v1/agent -X post -d ../../agent_import.json
```

## Deactivate Environment ##

When finished using the script, deactivate the Python virtual environement

* If using conda:
```
conda deactivate
```

* If using venv:
```
source .env/bin/deactivate
```

Note: To use subsequent times, simply reactivate environement (`conda activate dina` or `source .env/bin/activate`), and run.
