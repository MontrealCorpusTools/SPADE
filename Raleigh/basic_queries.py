import sys
import os

# =============== USER CONFIGURATION ===============
corpus_name = "raleigh"
corpus_dir = "/mnt/e/temp/raleigh/smallest_raleigh"
textgrid_format = "MFA"
vowel_inventory = []
base_dir = os.path.dirname(os.path.abspath(__file__))
script_dir = os.path.join(os.path.dirname(base_dir), 'Common')
reset = False  # Setting to True will cause the corpus to re-import

# SPADE CONFIG

dialect_code = 'sca'

lexicon_enrichment_files = ['/mnt/e/temp/raleigh/rule_applications.csv', '/mnt/e/temp/raleigh/sca_comparison.csv']
speaker_enrichment_file = '/mnt/e/temp/raleigh/speaker_information.txt'

# ==================================================

sys.path.insert(0, script_dir)

import common

import re
import time

from polyglotdb.utils import ensure_local_database_running
from polyglotdb import CorpusConfig

if __name__ == '__main__':
    print('Processing...')
    with ensure_local_database_running(corpus_name) as params:
        print(params)
        config = CorpusConfig(corpus_name, **params)
        config.formant_source = 'praat'
        # Common set up
        if reset:
            common.reset(config)
        common.loading(config, corpus_dir, textgrid_format)
        common.basic_enrichment(config, vowel_inventory)

        common.lexicon_enrichment(config, lexicon_enrichment_files, dialect_code)
        common.speaker_enrichment(config, speaker_enrichment_file)

        common.basic_queries(config)

        print('Finishing up!')