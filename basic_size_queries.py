import sys
import os
import argparse

base_dir = os.path.dirname(os.path.abspath(__file__))
script_dir = os.path.join(base_dir, 'Common')

sys.path.insert(0, script_dir)

import common

import re
import time

from polyglotdb.utils import ensure_local_database_running
from polyglotdb import CorpusConfig, CorpusContext

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('corpus_name', help='Name of the corpus')
    parser.add_argument('-r', '--reset', help="Reset the corpus", action='store_true')

    args = parser.parse_args()
    corpus_name = args.corpus_name
    reset = args.reset
    directories = [x for x in os.listdir(base_dir) if os.path.isdir(x) and x != 'Common']

    if args.corpus_name not in directories:
        print(
            'The corpus {0} does not have a directory (available: {1}).  Please make it with a {0}.yaml file inside.'.format(
                args.corpus_name, ', '.join(directories)))
        sys.exit(1)
    corpus_conf = common.load_config(corpus_name)
    print('Processing...')
    if reset:
        common.reset(corpus_name)
    with ensure_local_database_running(corpus_name, port=common.server_port, ip=common.server_ip, token=common.load_token()) as params:
        print(params)
        config = CorpusConfig(corpus_name, **params)
        config.formant_source = 'praat'
        with CorpusContext(config) as c:
            print(c.hierarchy)
        # Common set up
        common.loading(config, corpus_conf['corpus_directory'], corpus_conf['input_format'])

        common.basic_size_queries(config)

        print('Finishing up!')
