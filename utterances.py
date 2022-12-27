#######################################
## SPADE utterance extraction script ##
#######################################

## Processes and extracts start-times and end-times for all speaker utterances.
## Used for extracting data collected as part of the SPeech Across Dialects of English
## (SPADE) project.

## Input:
## - corpus name (e.g., Buckeye, SOTC)
## - corpus metadata (stored in a YAML file), which
##   specifies the path to the audio, transcripts and metadata
## Output:
## - CSV of utterance metadata for the corpus

import yaml
import time
from datetime import datetime
import sys
import os
import argparse

base_dir = os.path.dirname(os.path.abspath(__file__))
script_dir = os.path.join(base_dir, 'Common')

sys.path.insert(0, script_dir)

import common

from polyglotdb import CorpusContext
from polyglotdb.utils import ensure_local_database_running
from polyglotdb.config import CorpusConfig
from polyglotdb.io.enrichment import enrich_lexicon_from_csv

def utterance_export(config, corpus_name, corpus_directory, dialect_code, speakers, ignored_speakers=None):
    ## Main duration export function. Collects durational information into query format
    ## and outputs CSV file of measures
    csv_path = os.path.join(base_dir, corpus_name, '{}_utterances.csv'.format(corpus_name))

    with CorpusContext(config) as c:

        print("Beginning utterance export")
        beg = time.time()
        ## Process stress information for the vowel. All vowels in this analysis
        ## should contain primary stress, and so filter for stressed based on
        ## either the list of stressed vowels defined in the YAML file, or those
        ## which have had a primary stress label applied during lexical enrichment.
        q = c.query_graph(c.utterance).filter(c.utterance.speaker.name.not_in_(ignored_speakers))
        q = q.columns(c.utterance.speaker.name.column_name('speaker'),
                      c.utterance.id.column_name('utterance_label'),
                      c.utterance.begin.column_name('utterance_begin'),
                      c.utterance.end.column_name('utterance_end'),
                      c.utterance.following.begin.column_name('following_utterance_begin'),
                      c.utterance.following.end.column_name('following_utterance_end'),
                      c.utterance.speech_rate.column_name('speech_rate'),
                      c.utterance.discourse.name.column_name('discourse'),
                      c.utterance.discourse.speech_begin.column_name('discourse_begin'),
                      c.utterance.discourse.speech_end.column_name('discourse_end'))

        for sp, _ in c.hierarchy.speaker_properties:
            if sp == 'name':
                continue
            q = q.columns(getattr(c.utterance.speaker, sp).column_name(sp))

        ## Write the query to a CSV file
        print("Writing CSV")
        q.to_csv(csv_path)
        end = time.time()
        time_taken = time.time() - beg
        print('Query took: {}'.format(end - beg))
        print("Results for query written to " + csv_path)
        common.save_performance_benchmark(config, 'utterance_export', time_taken)

## Process command-line arguments (corpus metadata, corpus reset, etc).
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('corpus_name', help='Name of the corpus')
    parser.add_argument('-r', '--reset', help="Reset the corpus", action='store_true')
    parser.add_argument('-d', '--docker', help="This script is being called from Docker", action='store_true')

    args = parser.parse_args()
    corpus_name = args.corpus_name
    reset = args.reset
    docker = args.docker
    directories = [x for x in os.listdir(base_dir) if os.path.isdir(x) and x != 'Common']

    if args.corpus_name not in directories:
        print(
            'The corpus {0} does not have a directory (available: {1}).  Please make it with a {0}.yaml file inside.'.format(
                args.corpus_name, ', '.join(directories)))
        sys.exit(1)
    corpus_conf = common.load_config(corpus_name)
    print('Processing...')

    # sanity check database access
    common.check_database(corpus_name)

    ignored_speakers = corpus_conf.get('ignore_speakers', [])
    stressed_vowels = corpus_conf.get('stressed_vowels', [])

    if reset:
        common.reset(corpus_name)
    ip = common.server_ip
    if docker:
        ip = common.docker_ip

    ## start processing the corpus
    with ensure_local_database_running(corpus_name, port=common.server_port, ip=ip, token=common.load_token()) as params:
        config = CorpusConfig(corpus_name, **params)
        config.formant_source = 'praat'
        # Common set up
        ## Check if the corpus already exists as a database: if not, import the audio and
        ## transcripts and store in graph format
        common.loading(config, corpus_conf['corpus_directory'], corpus_conf['input_format'])

        ## Add information to the corpus regarding lexical, speaker, and linguistic information
        common.lexicon_enrichment(config, corpus_conf['unisyn_spade_directory'], corpus_conf['dialect_code'])
        common.speaker_enrichment(config, corpus_conf['speaker_enrichment_file'])
        common.basic_enrichment(config, corpus_conf['vowel_inventory'] + corpus_conf['extra_syllabic_segments'], corpus_conf['pauses'])

        ## Call the utterance export function, as defined above
        utterance_export(config, corpus_name, corpus_conf['corpus_directory'], corpus_conf['dialect_code'], corpus_conf['speakers'], ignored_speakers=ignored_speakers)
        print('Finishing up!')
