###################################
## SPADE formant analysis script ##
###################################

## Processes and extracts 'static' (single point) formant values, along with linguistic
## and acoustic information from corpora collected as part of the SPeech Across Dialects
## of English (SPADE) project.

## Input:
## - corpus name (e.g., Buckeye, SOTC)
## - corpus metadata (stored in a YAML file)
##   this file should specify the path to the
##   audio, transcripts, metadata files (e.g.,
##   speaker, lexicon), and the a datafile containing
##   prototype formant values to be used for formant
##   estimation
## Output:
## - CSV of single-point vowel measurements (1 row per token),
##   with columns for the linguistic, acoustic, and speaker information
##   associated with that token

import sys
import os
import argparse

base_dir = os.path.dirname(os.path.abspath(__file__))
script_dir = os.path.join(base_dir, 'Common')

sys.path.insert(0, script_dir)

drop_formant = True

import common

from polyglotdb.utils import ensure_local_database_running
from polyglotdb import CorpusConfig

## Define and process command line arguments
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('corpus_name', help='Name of the corpus')
    parser.add_argument('-r', '--reset', help="Reset the corpus", action='store_true')
    parser.add_argument('-f', '--formant_reset', help="Reset formant measures", action = 'store_true', default=False)
    parser.add_argument('-d', '--docker', help="This script is being called from Docker", action='store_true')

    args = parser.parse_args()
    corpus_name = args.corpus_name
    reset = args.reset
    docker = args.docker
    reset_formants = args.formant_reset
    directories = [x for x in os.listdir(base_dir) if os.path.isdir(x) and x != 'Common']

    ## sanity-check the corpus name (i.e., that it directs to a YAML file)
    if args.corpus_name not in directories:
        print(
            'The corpus {0} does not have a directory (available: {1}).  Please make it with a {0}.yaml file inside.'.format(
                args.corpus_name, ', '.join(directories)))
        sys.exit(1)
    corpus_conf = common.load_config(corpus_name)
    print('Processing...')

    ## apply corpus reset or docker application
    ## if flags are used
    if reset:
        common.reset(corpus_name)
    ip = common.server_ip
    if docker:
        ip = common.docker_ip
    with ensure_local_database_running(corpus_name, port=common.server_port, ip=ip, token=common.load_token()) as params:
        print(params)
        config = CorpusConfig(corpus_name, **params)
        config.formant_source = 'praat'

        ## Common set up: see commony.py for details of these functions ##
        ## Check if the corpus already has an associated graph object; if not,
        ## perform importing and parsing of the corpus files
        common.loading(config, corpus_conf['corpus_directory'], corpus_conf['input_format'])

        ## Perform linguistic, speaker, and acoustic enrichment
        common.lexicon_enrichment(config, corpus_conf['unisyn_spade_directory'], corpus_conf['dialect_code'])
        common.speaker_enrichment(config, corpus_conf['speaker_enrichment_file'])

        common.basic_enrichment(config, corpus_conf['vowel_inventory'] + corpus_conf['extra_syllabic_segments'], corpus_conf['pauses'])

        ## Check if the YAML specifies the path to the YAML file
        ## if not, load the prototypes file from the default location
        ## (within the SPADE corpus directory)
        vowel_prototypes_path = corpus_conf.get('vowel_prototypes_path','')
        if not vowel_prototypes_path:
            vowel_prototypes_path = os.path.join(base_dir, corpus_name, '{}_prototypes.csv'.format(corpus_name))

        ## Determine the class of phone labels to be used for formant analysis
        ## based on lists provided in the YAML file.
        if corpus_conf['stressed_vowels']:
            vowels_to_analyze = corpus_conf['stressed_vowels']
        else:
            vowels_to_analyze = corpus_conf['vowel_inventory']

        ## Perform formant estimation and analysis
        ## see common.py for the details of this implementation
        common.formant_acoustic_analysis(config, vowels_to_analyze, vowel_prototypes_path, drop_formant=drop_formant, reset_formants=reset_formants)

        ## Output the query (determined in common.py) as a CSV file
        common.formant_export(config, corpus_name, corpus_conf['dialect_code'],
                              corpus_conf['speakers'], vowels_to_analyze, output_tracks=False)
        print('Finishing up!')
