####################################
## SPADE duration analysis script ##
####################################

## Processes and extracts linguistic and acoustic information pertaining to vowel length
## for monosyllabic stressed vowels followed by voiced and voiceless consonants.
## Used for extracting data collected as part of the SPeech Across Dialects of English
## (SPADE) project.

## Input:
## - corpus name (e.g., Buckeye, SOTC)
## - corpus metadata (stored in a YAML file), which
##   specifies the path to the audio, transcripts and metadata
## Output:
## - CSV of durational measures and linguistic information
##   associated with the token

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

def sibilant_export(config, corpus_name, dialect_code, speakers, ignored_speakers=None):
    ## Extract sibilant information without filters
    csv_path = os.path.join(base_dir, corpus_name, '{}_sibilants_full.csv'.format(corpus_name))

    with CorpusContext(config) as c:
        print("Beginning sibilant export")
        beg = time.time()
        # only run on segments with a sibilant label
        q = c.query_graph(c.phone).filter(c.phone.subset == 'sibilant')
        # ensure that all phones are associated with a speaker
        if speakers:
            q = q.filter(c.phone.speaker.name.in_(speakers))
        if ignored_speakers:
            q = q.filter(c.phone.speaker.name.not_in_(ignored_speakers))
        # this exports data for all sibilants
        # information about the phone, syllable, and word (label, start/endpoints etc)
        # also spectral properties of interest (COG, spectral peak/slope/spread)
        qr = q.columns(c.phone.speaker.name.column_name('speaker'),
                       c.phone.discourse.name.column_name('discourse'),

                       # phone-level information (label, start/endpoint, etc)
                       c.phone.id.column_name('phone_id'), c.phone.label.column_name('phone_label'),
                       c.phone.begin.column_name('phone_begin'), c.phone.end.column_name('phone_end'),
                       c.phone.duration.column_name('duration'),

                       # surrounding phone information
                       c.phone.following.label.column_name('following_phone'),
                       c.phone.previous.label.column_name('previous_phone'),

                       # word and syllable information (e.g., stress,
                       # onset/nuclus/coda of the syllable)
                       # determined from maximum onset algorithm in
                       # basic_enrichment function
                       c.phone.syllable.word.label.column_name('word'),
                       c.phone.syllable.word.id.column_name('word_id'),
                       c.phone.syllable.stress.column_name('syllable_stress'),
                       c.phone.syllable.phone.filter_by_subset('onset').label.column_name('onset'),
                       c.phone.syllable.phone.filter_by_subset('nucleus').label.column_name('nucleus'),
                       c.phone.syllable.phone.filter_by_subset('coda').label.column_name('coda'),

                       # acoustic information of interest (spectral measurements)
                       c.phone.cog.column_name('cog'), c.phone.peak.column_name('peak'),
                       c.phone.slope.column_name('slope'), c.phone.spread.column_name('spread'))

        # get columns of speaker metadata
        for sp, _ in c.hierarchy.speaker_properties:
            if sp == 'name':
                continue
            q = q.columns(getattr(c.phone.speaker, sp).column_name(sp))

        # as Buckeye has had labels changed to reflect phonetic realisation,
        # need to also get the original transcription for comparison with
        # other corpora
        if c.hierarchy.has_token_property('word', 'surface_transcription'):
            print('getting underlying and surface transcriptions')
            q = q.columns(
                    c.phone.word.transcription.column_name('word_underlying_transcription'),
                    c.phone.word.surface_transcription.column_name('word_surface_transcription'))
        # write the query to a CSV
        qr.to_csv(csv_path)
        end = time.time()
        time_taken = time.time() - beg
        print('Query took: {}'.format(end - beg))
        print("Results for query written to " + csv_path)
        save_performance_benchmark(config, 'sibilant_full_export', time_taken)

## Process command-line arguments (corpus metadata, corpus reset, etc).
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('corpus_name', help='Name of the corpus')
    parser.add_argument('-r', '--reset', help="Reset the corpus", action='store_true')
    parser.add_argument('-b', '--baseline', help='Calculate baseline duration', action='store_true')
    parser.add_argument('-d', '--docker', help="This script is being called from Docker", action='store_true')

    args = parser.parse_args()
    corpus_name = args.corpus_name
    reset = args.reset
    docker = args.docker
    baseline = args.baseline
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

        ## Call the duration export function, as defined above
        common.sibilant_acoustic_analysis(config, corpus_conf['sibilant_segments'], igored_speakers=ignored_speakers
        sibilant_full_export(config, corpus_name, corpus_conf['corpus_directory'], corpus_conf['dialect_code'], corpus_conf['speakers'], ignored_speakers=ignored_speakers)
        print('Finishing up!')
