## Requirements ##
  * Python 3.8 or 3.9
  * Conda 4.8+ (recommended)

Note: If not using Conda, then depending on the way you installed Python, you may have to replace the call to `python3.8` by `python3` or `python`.

Instructions to install Python 3.8:
* From [PPA](https://linuxize.com/post/how-to-install-python-3-8-on-ubuntu-18-04/) (you will also need to install the package `python3.8-venv`)
* From [source](https://tecadmin.net/install-python-3-8-ubuntu/)

## Initial Setup ##

1. Create and activate your virtual environment
* If you have conda installed:
```
conda create --name dina-test-env python=3.8
conda activate dina-test-env
```

* OR with venv
```
python3.8 -m venv dina-test-env
source dina-test-env/bin/activate
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

**Refer to https://github.com/DINA-Web/object-store-specs to see current API specifications**

Get: 
```
python access_api_with_keycloak_token.py -u http://api.dina.local/objectstore/api/v1/object-subtype
```
Post:
```
python access_api_with_keycloak_token.py -X POST -u http://api.dina.local/agent/api/v1/agent -H '{"Content-Type": "application/vnd.api+json", "Accept": "application/vnd.api+json"}' -d '{"data": {"type": "agent", "attributes": {"displayName": "Samah Hassan", "email": "samah@email.com"}}}'
```

```
python access_api_with_keycloak_token.py -u http://api.dina.local/agent/api/v1/agent -X post -f path/to/file.json
```

## Deactivate Environment ##

When finished using the script, deactivate the Python virtual environement

* If using conda:
```
conda deactivate
```

* Otherwise:
```
deactivate
```
