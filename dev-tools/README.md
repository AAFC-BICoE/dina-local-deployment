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
python access_api_with_keycloak_token.py [-h] -a API_URL [-d DATA] [-f JSON_FILE] [-X {GET,POST,PATCH,DELETE}] [-H HEADERS]
optional arguments:
  -h    --help              show this help message and exit
  -a    --api_url           API URL of request
  -d    --data              json object
  ~-f    --json_file        JSON_FILE~
  -H    --headers HEADERS   String representation of a json object
  -X    --request           {GET,POST,PATCH,DELETE}. Default GET.
   
```
Usage examples:

Get: 
```
python access_api_with_keycloak_token.py --url http://api.dina.local/agent/api/v1/agent
```
Post:
```
python access_api_with_keycloak_token.py -X POST -a http://api.dina.local/agent/api/v1/agent -H '{"Content-Type": "application/vnd.api+json", "Accept": "application/vnd.api+json"}' --data '{"data": {"type": "agent", "attributes": {"displayName": "Samah Hassan", "email": "samah@email.com"}}}'
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
