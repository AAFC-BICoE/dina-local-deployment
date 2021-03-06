import argparse
import json
from keycloak import KeycloakOpenID
import logging
import os
import requests
import yaml

from urllib.parse import urlparse

KEYCLOAK_CONFIG_PATH = './keycloak-config.yml'

def _parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-u', '--url', required=True, help='API URL of request')
    parser.add_argument('-d', '--data', required=False, 
        help='Python string representation of a dictionary')
    parser.add_argument('-f', '--json_file', default=None)
    parser.add_argument('-H', '--headers', 
        help='Python dictionary, e.g. \'{"Content-Type": "application/vnd.api+json", "Accept": "application/vnd.api+json"}\'')
    parser.add_argument('-X', '--request', default='get', 
        choices=['get', 'post', 'patch', 'delete', 'GET', 'POST', 'PATCH', 'DELETE'])
    
    return parser.parse_args()


def load_configuration(config_path=KEYCLOAK_CONFIG_PATH):
    """Load configurations from file"""
    try:
        config_file = open(config_path, 'r')
        config = yaml.safe_load(config_file)
        config_file.close()
        return config
    except yaml.YAMLError as exc:
        logging.error('Error in configuration file. Cannot execute.')
        logging.error(exc)


def get_keycloak_token(configs):
    """Retrieves Keycloak bearer token"""
    keycloak_openid = KeycloakOpenID(
        server_url=configs['url'], 
        client_id=configs['client_id'],
        realm_name=configs['realm_name'],
        client_secret_key=None,
        verify=configs['secure'])

    return keycloak_openid.token(configs['username'], configs['password'])


def load_json_data(file):
    if not file:
        return None
    if os.path.isfile(file) and file.endswith('.json'):
        with open(file, 'r') as f:
            json_data = json.load(f)
            return json_data
    elif not os.path.isfile(file):
        raise FileNotFoundError('File not found.')
    else:
        raise TypeError('Invalid filetype. Must be json file.')


def main():
    # Load arguments
    args = _parse_args()
    url = args.url
    json_file = args.json_file
    method = args.request.upper()

    configs = load_configuration()
    token = get_keycloak_token(configs)
    authorization_string = "Bearer {}".format(token['access_token'])

    # Handle headers
    if args.headers:
         headers = json.loads(args.headers)
    else:
        headers = {}
    headers.update({"Authorization": authorization_string}) 

    # Handle request
    if method == 'GET':
        res = requests.get(url, headers=headers)
        if not res.ok:
            res.raise_for_status()
    else:
        data = args.data
 
        try:
            json_data = load_json_data(args.json_file)
        except (FileNotFoundError, TypeError) as e:
            print('Error encountered loading json file {}:\n{}'.format(json_file, e))
            return

        if not "Content-Type" in headers.keys():
            headers.update({"Content-Type":"application/vnd.api+json"})

        if method == 'POST':
            res = requests.post(url, data=data, json=json_data, headers=headers)

        elif method == 'PATCH':
            res = requests.patch(url, data=data, json=json_data, headers=headers)
        
        elif method == 'DELETE':
            res = requests.delete(url, data=data, json=json_data, headers=headers)
    
    if not res.ok:
        res.raise_for_status()
    
    print(res.text)


if __name__ == '__main__':
    main()
