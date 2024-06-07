import os
import sys

if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise ValueError('Please provide the Grafana datasources template file as a parameter on the command-line.')
    template_path = sys.argv[1]

    endpoint = os.environ.get('KSQL_ENDPOINT')
    api_key = os.environ.get('KSQL_API_KEY')
    api_secret = os.environ.get('KSQL_API_SECRET')

    with open(template_path, 'r') as file:
        data = file.read().replace('KSQL_ENDPOINT', endpoint).replace("KSQL_API_KEY", api_key).replace("KSQL_API_SECRET", api_secret)

    print(data)
