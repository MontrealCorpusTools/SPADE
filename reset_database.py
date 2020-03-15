import sys
import os
import argparse

base_dir = os.path.dirname(os.path.abspath(__file__))
script_dir = os.path.join(base_dir, 'Common')

sys.path.insert(0, script_dir)

import common

from polyglotdb.client.client import PGDBClient

token = common.load_token()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('corpus_name', help='Name of the corpus')
    parser.add_argument('-d', '--docker', help="This script is being called from Docker", action='store_true')

    args = parser.parse_args()
    corpus_name = args.corpus_name
    docker = args.docker
    directories = [x for x in os.listdir(base_dir) if os.path.isdir(x) and x != 'Common']

    if args.corpus_name not in directories:
        print(
            'The corpus {0} does not have a directory (available: {1}).  Please make it with a {0}.yaml file inside.'.format(
                args.corpus_name, ', '.join(directories)))
        sys.exit(1)
    corpus_conf = common.load_config(corpus_name)
    ip = common.server_ip
    if docker:
        ip = common.docker_ip
    print('Processing...')
    client = PGDBClient('http://{}:{}'.format(ip, 8080), token=token)
    client.delete_database(corpus_name)
