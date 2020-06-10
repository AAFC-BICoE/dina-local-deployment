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
    parser.add_argument('-u', '--url', required = True, help='API URL of request')
    parser.add_argument('-d', '--data', required=False, 
        help='Python string representation of a dictionary')
    parser.add_argument('-f', '--json_file', required=False)
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
    """Retrieves Keycolak bearer token"""
    keycloak_openid = KeycloakOpenID(
        server_url=configs['url'], 
        client_id='objectstore',
        realm_name=configs['realm_name'],
        client_secret_key=None,
        verify=configs['secure'])

    return keycloak_openid.token(configs['username'], configs['password'])


def main():
    # Load arguments
    args = _parse_args()
    url = args.url
    method = args.request.upper()

    configs = load_configuration()
    token = get_keycloak_token(configs)
    authorization_string = "Bearer {}".format(token)

    # Handle headers
    if args.headers:
         headers = json.loads(args.headers)
    else:
        headers = {}
    headers.update({"Authorization": authorization_string}) 

    # Handle request
    if method == 'GET':
        res = requests.get(url, headers=headers)

    else:
        data = args.data
        if args.json_file is not None:
            file = args.json_file
            if os.path.isfile(file) and file.endswith('.json'):
                with open(file, 'r') as f:
                       json_data = file.load(f)
            else:
                print('Expecting json filetype.')
                exit(1)
        else:
            json_data = None
        
        if not "Content-Type" in headers.keys():
            headers.update({"Content-Type":"application/vnd.api+json"})

        if method == 'POST':
            res = requests.post(url, data=data, json=json_data, headers=headers)

        elif method == 'PATCH':
            res = requests.patch(rl, data=data, json=json_data, headers=headers)
        
        elif method == 'DELETE':
            res = requests.delete(url, data=data, json=json_data, headers=headers)


if __name__ == '__main__':
    main()
