#########################################
## SPADE sibilant full analysis script ##
#########################################

## Processes and extracts linguistic and acoustic information pertaining to sibilants
## for *all* sibilant segments in the corpus
## Used for extracting data collected as part of the SPeech Across Dialects of English
## (SPADE) project.

## Input:
## - corpus name (e.g., Buckeye, SOTC)
## - corpus metadata (stored in a YAML file), which
##   specifies the path to the audio, transcripts and metadata
## Output:
## - CSV of sibilant measures and linguistic information
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

def sibilant_full_export(config, corpus_name, dialect_code, speakers, ignored_speakers):
    ## Extract sibilant information without filters
    csv_path = os.path.join(base_dir, corpus_name, '{}_sibilants_full.csv'.format(corpus_name))

    with CorpusContext(config) as c:
        print("Beginning sibilant full export")
        beg = time.time()
        # only run on segments with a sibilant label
        # this 'sibilant' subset is defined in the sibilant_acoustic_analysis function in
        # common.py. Be default this uses the set of segments defined as 'sibilant_segments'
        # in the corpus-specific YAML file.
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
                       c.phone.following.begin.column_name('following_phone_begin'),
                       c.phone.following.end.column_name('following_phone_end'),
                       c.phone.following.duration.column_name('following_phone_duration'),

                       c.phone.previous.label.column_name('previous_phone'),
                       c.phone.previous.begin.column_name('previous_phone_begin'),
                       c.phone.previous.end.column_name('previous_phone_end'),
                       c.phone.previous.duration.column_name('previous_phone_duration'),

                       # word and syllable information (e.g., stress,
                       # onset/nuclus/coda of the syllable)
                       # determined from maximum onset algorithm in
                       # basic_enrichment function
                       c.phone.word.label.column_name('word'),
                       c.phone.word.id.column_name('word_id'),
                       c.phone.word.stresspattern.column_name('word_stresspattern'),
                       c.phone.syllable.label.column_name('syllable_label'),
                       c.phone.syllable.stress.column_name('syllable_stress'),
                       c.phone.syllable.position_in_word.column_name('syllable_position'),
                       c.phone.syllable.num_phones.column_name('syllable_num_phones'),
                       c.phone.syllable.phone.filter_by_subset('onset').label.column_name('onset'),
                       c.phone.syllable.phone.filter_by_subset('nucleus').label.column_name('nucleus'),
                       c.phone.syllable.phone.filter_by_subset('coda').label.column_name('coda'),

                       c.phone.syllable.following.label.column_name('following_syllable_label'),
                       c.phone.syllable.following.begin.column_name('following_syllable_begin'),
                       c.phone.syllable.following.end.column_name('following_syllable_end'),
                       c.phone.syllable.following.duration.column_name('following_syllable_duration'),
                       c.phone.syllable.following.phone.filter_by_subset('onset').label.column_name('following_onset'),
                       c.phone.syllable.following.phone.filter_by_subset('nucleus').label.column_name('following_nucleus'),
                       c.phone.syllable.following.phone.filter_by_subset('coda').label.column_name('following_coda'),

                       c.phone.syllable.previous.label.column_name('previous_syllable_label'),
                       c.phone.syllable.previous.begin.column_name('previous_syllable_begin'),
                       c.phone.syllable.previous.end.column_name('previous_syllable_end'),
                       c.phone.syllable.previous.duration.column_name('previous_syllable_duration'),
                       c.phone.syllable.previous.phone.filter_by_subset('onset').label.column_name('previous_onset'),
                       c.phone.syllable.previous.phone.filter_by_subset('nucleus').label.column_name('previous_nucleus'),
                       c.phone.syllable.previous.phone.filter_by_subset('coda').label.column_name('previous_coda'),

                       c.phone.word.following.label.column_name('following_word_label'),
                       c.phone.word.following.begin.column_name('following_word_begin'),
                       c.phone.word.following.end.column_name('following_word_end'),
                       c.phone.word.following.duration.column_name('following_word_duration'),
                       c.phone.word.following.stresspattern.column_name('following_word_stresspattern'),

                       c.phone.word.previous.label.column_name('previous_word_label'),
                       c.phone.word.previous.begin.column_name('previous_word_begin'),
                       c.phone.word.previous.end.column_name('previous_word_end'),
                       c.phone.word.previous.duration.column_name('previous_word_duration'),
                       c.phone.word.previous.stresspattern.column_name('previous_word_stresspattern'),

                       c.phone.utterance.label.column_name('utterance_label'),
                       c.phone.utterance.id.column_name('utterance_id'),
                       c.phone.utterance.begin.column_name('utterance_begin'),
                       c.phone.utterance.end.column_name('utterance_end'),
                       c.phone.utterance.duration.column_name('utterance_duration'),
                       c.phone.utterance.num_words.column_name('utterance_num_words'),
                       c.phone.utterance.num_syllables.column_name('utterance_num_syllables'),
                       c.phone.utterance.speech_rate.column_name('utterance_speech_rate'),

                       # acoustic information of interest (spectral measurements)
                       # measured as part of the sibilant_acoustic_analysis function in
                       # common.py
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
        common.save_performance_benchmark(config, 'sibilant_full_export', time_taken)
        print(c.hierarchy)

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
        ## These functions are defined in common.py
        common.lexicon_enrichment(config, corpus_conf['unisyn_spade_directory'], corpus_conf['dialect_code'])
        common.speaker_enrichment(config, corpus_conf['speaker_enrichment_file'])
        common.basic_enrichment(config, corpus_conf['vowel_inventory'] + corpus_conf['extra_syllabic_segments'], corpus_conf['pauses'])

        ## Call the siblant analysis function
        ## the specifics of the sibilant acoustic analysis is found in common.py; the segments
        ## over which it applies is defined in the corpus-specific YAML file (under
        ## 'sibilant_segments'). Change the list of segments in order to change over what phones
        ## the sibilant enrichment/extraction applies
        common.sibilant_acoustic_analysis(config, corpus_conf['sibilant_segments'], ignored_speakers=ignored_speakers)
        ## Once the set of sibilant tokens have been enriched for acoustic measures,
        ## extract the data in tabular (CSV) format. Columns included in this output file
        ## are defined in the function at the beginning of this script
        sibilant_full_export(config, corpus_name, corpus_conf['dialect_code'], corpus_conf['speakers'], ignored_speakers=ignored_speakers)
        print('Finishing up!')
