####################################
## SPADE sibilant analysis script ##
####################################

## Performs processes and extracts linguistic and acoustic properties of sibilants (/s/, /sh/)
## from corpora collected as part of the SPeech Across Dialects of English (SPADE) project.

## Input:
## - corpus name (e.g., Buckeye SOTC)
## - corpus metadata (placed in an associated YAML file)
##   specifies paths to corpus audio, transcripts, and metadata
## Output:
## - CSV of sibilant measurements

import sys
import os
import argparse

base_dir = os.path.dirname(os.path.abspath(__file__))
script_dir = os.path.join(base_dir, 'Common')

sys.path.insert(0, script_dir)

import common

from polyglotdb.utils import ensure_local_database_running
from polyglotdb.config import CorpusConfig

if __name__ == '__main__':
    # process command-line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('corpus_name', help='Name of the corpus')
    parser.add_argument('-r', '--reset', help="Reset the corpus", action='store_true')
    parser.add_argument('-d', '--docker', help="This script is being called from Docker", action='store_true')

    args = parser.parse_args()
    corpus_name = args.corpus_name
    reset = args.reset
    docker = args.docker
    directories = [x for x in os.listdir(base_dir) if os.path.isdir(x) and x != 'Common']

    # check that the corpus has an associated YAML configuration file
    if args.corpus_name not in directories:
        print(
            'The corpus {0} does not have a directory (available: {1}).  Please make it with a {0}.yaml file inside.'.format(
                args.corpus_name, ', '.join(directories)))
        sys.exit(1)
    corpus_conf = common.load_config(corpus_name)

    ## Process configuration file
    included_speakers = corpus_conf.get('speakers', [])
    ignored_speakers = corpus_conf.get('ignore_speakers', [])
    print('Processing...')
    if reset:
        common.reset(corpus_name)
    ip = common.server_ip
    if docker:
        ip = common.docker_ip
    with ensure_local_database_running(corpus_name, port=common.server_port, ip=ip, token=common.load_token()) as params:
        print(params)
        config = CorpusConfig(corpus_name, **params)
        config.formant_source = 'praat'

        # Process corpus data (lexicon, speakers, linguistic structure)
        common.loading(config, corpus_conf['corpus_directory'], corpus_conf['input_format'])
        common.lexicon_enrichment(config, corpus_conf['unisyn_spade_directory'], corpus_conf['dialect_code'])
        common.speaker_enrichment(config, corpus_conf['speaker_enrichment_file'])
        common.basic_enrichment(config, corpus_conf['vowel_inventory'] + corpus_conf['extra_syllabic_segments'], corpus_conf['pauses'])

        # Analyse sibilant data, generate query and export data
        common.sibilant_acoustic_analysis(config, corpus_conf['sibilant_segments'], ignored_speakers=ignored_speakers)
        common.sibilant_export(config, corpus_name, corpus_conf['dialect_code'], included_speakers, ignored_speakers=ignored_speakers)
        print('Finishing up!')
