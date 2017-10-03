import sys
import os

# =============== USER CONFIGURATION ===============
corpus_name = "raleigh"
corpus_dir = "/mnt/e/temp/raleigh/smallest_raleigh"

textgrid_format = "MFA"
vowel_inventory = ['ER0', 'IH2', 'EH1', 'AE0', 'UH1', 'AY2', 'AW2', 'UW1', 'OY2', 'OY1', 'AO0', 'AH2', 'ER1', 'AW1',
                   'OW0', 'IY1', 'IY2', 'UW0', 'AA1', 'EY0', 'AE1', 'AA0', 'OW1', 'AW0', 'AO1', 'AO2', 'IH0', 'ER2',
                   'UW2', 'IY0', 'AE2', 'AH0', 'AH1', 'UH2', 'EH2', 'UH0', 'EY1', 'AY0', 'AY1', 'EH0', 'EY2', 'AA2',
                   'OW2', 'IH1']
base_dir = os.path.dirname(os.path.abspath(__file__))
script_dir = os.path.join(os.path.dirname(base_dir), 'Common')
reset = False  # Setting to True will cause the corpus to re-import

# SPADE CONFIG

dialect_code = 'sca'

lexicon_enrichment_files = ['/mnt/e/temp/raleigh/rule_applications.csv', '/mnt/e/temp/raleigh/sca_comparison.csv']
speaker_enrichment_file = '/mnt/e/temp/raleigh/speaker_information.txt'

sibilant_segments = ['S', 'Z', 'SH', 'ZH']

# Paths to scripts and praat
script_path = os.path.join(script_dir, 'sibilant_jane_optimized.praat')
csv_path = os.path.join(base_dir, corpus_name + "_sibilants.csv")
# ==================================================

sys.path.insert(0, script_dir)

import common

from polyglotdb.utils import ensure_local_database_running
from polyglotdb.config import CorpusConfig

if __name__ == '__main__':
    print('Processing...')
    with ensure_local_database_running(corpus_name) as params:
        config = CorpusConfig(corpus_name, **params)
        config.formant_source = 'praat'
        # Common set up
        if reset:
            common.reset(config)
        common.loading(config, corpus_dir, textgrid_format)
        common.basic_enrichment(config, vowel_inventory)

        common.lexicon_enrichment(config, lexicon_enrichment_files, dialect_code)
        common.speaker_enrichment(config, speaker_enrichment_file)

        # Formant specific analysis
        common.sibilant_acoustic_analysis(config, sibilant_segments, script_path)
        common.sibilant_export(config, csv_path, dialect_code)
        print('Finishing up!')
