import sys
import os
import argparse

base_dir = os.path.dirname(os.path.abspath(__file__))

from polyglotdb.client.client import PGDBClient

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('corpus_name', help='Name of the corpus')

    args = parser.parse_args()
    corpus_name = args.corpus_name
    reset = args.reset
    directories = [x for x in os.listdir(base_dir) if os.path.isdir(x) and x != 'Common']

    if args.corpus_name not in directories:
        print(
            'The corpus {0} does not have a directory (available: {1}).  Please make it with a {0}.yaml file inside.'.format(
                args.corpus_name, ', '.join(directories)))
        sys.exit(1)
    print('Processing...')
    client = PGDBClient('http://localhost:8000')
    client.delete_database(corpus_name)
