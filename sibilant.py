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

    ## Parse conf
    included_speakers = corpus_conf.get('speakers', [])
    ignored_speakers = corpus_conf.get('ignore_speakers', [])
    print('Processing...')
    with ensure_local_database_running(corpus_name, port=8080, token=common.load_token()) as params:
        config = CorpusConfig(corpus_name, **params)
        config.formant_source = 'praat'
        # Common set up
        if reset:
            common.reset(config)
        common.loading(config, corpus_conf['corpus_directory'], corpus_conf['input_format'])

        common.lexicon_enrichment(config, corpus_conf['unisyn_spade_directory'], corpus_conf['dialect_code'])
        common.speaker_enrichment(config, corpus_conf['speaker_enrichment_file'])

        common.basic_enrichment(config, corpus_conf['vowel_inventory'] + corpus_conf['extra_syllabic_segments'], corpus_conf['pauses'])

        # Formant specific analysis
        common.sibilant_acoustic_analysis(config, corpus_conf['sibilant_segments'], ignored_speakers=ignored_speakers)
        common.sibilant_export(config, corpus_name, corpus_conf['dialect_code'], included_speakers, ignored_speakers=ignored_speakers)
        print('Finishing up!')
