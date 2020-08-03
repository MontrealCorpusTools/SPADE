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

def duration_export(config, corpus_name, corpus_directory, dialect_code, speakers, vowels, stressed_vowels=None, baseline = False, ignored_speakers=None):
    ## Main duration export function. Collects durational information into query format
    ## and outputs CSV file of measures
    csv_path = os.path.join(base_dir, corpus_name, '{}_duration.csv'.format(corpus_name))

    with CorpusContext(config) as c:

        ## Since the Buckeye corpus contains *phonetic* (not phonological) transcriptions of
        ## segments, it is necessary to also pull in the 'underlying' transcription, as to
        ## make the transcription scheme analogous with other SPADE corpora
        if corpus_name == 'spade-Buckeye':
            print("Processing {}".format(corpus_name))
            if not c.hierarchy.has_type_property('word', "ContainsVowelObstruent"):
                print('Classifying Buckeye vowel-obstruent pairs')
                enrich_lexicon_from_csv(c,os.path.join(corpus_directory,"corpus-data/enrichment/buckeye_obstruents.csv"))

        print("Beginning duration export")
        beg = time.time()
        ## Define the list of consonants of interest: Here, these are stops,
        ## fricatives, affricates, nasals, and liquids
        consonants = ['p', 'P', 't', 'T', 'k', 'K', 'b', 'B', 'd', 'D', 'g', 'G',
                      'F', 'f', 'V', 'v', 'N', 'n', 'm', 'M', 'NG', 'TH', 'DH',
                      'l', 'L', 'ZH', 'x', 'X', 'r', 'R', 's', 'S', 'sh', 'SH',
                      'z','Z', 'zh', 'ZH', 'J', 'C', 'tS', 'dZ', 'tq']
        ## Process stress information for the vowel. All vowels in this analysis
        ## should contain primary stress, and so filter for stressed based on
        ## either the list of stressed vowels defined in the YAML file, or those
        ## which have had a primary stress label applied during lexical enrichment.
        if stressed_vowels:
            q = c.query_graph(c.phone).filter(c.phone.label.in_(stressed_vowels))
            q = q.filter(c.phone.following.end == c.phone.syllable.end)
            q = q.filter(c.phone.following.end == c.phone.syllable.word.utterance.end)
            q = q.filter(c.phone.following.label.in_(consonants))
            q = q.filter(c.phone.syllable.word.num_syllables == 1)
        else:
            q = c.query_graph(c.phone).filter(c.phone.label.in_(vowels))
            q = q.filter(c.phone.following.end == c.phone.syllable.end)
            q = q.filter(c.phone.following.end == c.phone.syllable.word.utterance.end)
            q = q.filter(c.phone.following.label.in_(consonants))
            q = q.filter(c.phone.word.stresspattern == "1")
            q = q.filter(c.phone.syllable.stress == "1")

        ## Check that the vowel is in a vowel-obstruent cluster
        ## (i.e., no complex clusters)
        print(c.hierarchy)
        if c.hierarchy.has_type_property('word', 'containsvowelobstruent'):
            q = q.filter(c.phone.word.containsvowelobstruent == True)

        if speakers:
            q = q.filter(c.phone.speaker.name.in_(speakers))

        if ignored_speakers:
            q = q.filter(c.phone.speaker.name.not_in_(ignored_speakers))

        print("Applied filters")
        ## Define the columns to be included in the final CSV file.
        ## This list contains columns for the vowels start and endpoint in the file,
        ## its duration, its surrounding phonological context, lexcial information
        ## (e.g., stress, dialect-specific realisation), syllable properties,
        ## and higher-level information (e.g., speech rate, speaker metadata).
        q = q.columns(c.phone.label.column_name('phone_label'),
                      c.phone.begin.column_name('phone_begin'),
                      c.phone.end.column_name('phone_end'),
                      c.phone.duration.column_name('phone_duration'),
                      c.phone.previous.label.column_name('previous_phone'),
                      c.phone.following.label.column_name('following_phone'),
                      c.phone.following.duration.column_name('following_duration'),
                      c.phone.word.unisynprimstressedvowel1.column_name('word_unisyn'),
                      c.phone.word.label.column_name('word_label'),
                      c.phone.word.begin.column_name('word_begin'),
                      c.phone.word.end.column_name('word_end'),
                      c.phone.word.duration.column_name('word_duration'),
                      c.phone.syllable.label.column_name('syllable_label'),
                      c.phone.syllable.duration.column_name('syllable_duration'),
                      c.phone.word.stresspattern.column_name('word_stresspattern'),
                      c.phone.syllable.stress.column_name('syllable_stress'),
                      c.phone.utterance.speech_rate.column_name('speech_rate'),
                      c.phone.utterance.id.column_name('utterance_label'),
                      c.phone.speaker.name.column_name('speaker_name'),
                      c.phone.syllable.end.column_name('syllable_end'),
                      c.phone.utterance.end.column_name('utterance_end'))
        for sp, _ in c.hierarchy.speaker_properties:
            if sp == 'name':
                continue
            q = q.columns(getattr(c.phone.speaker, sp).column_name(sp))

        ## Also include columns of underlying ('phonological') transcription
        ## if using the Buckeye corpus
        if c.hierarchy.has_token_property('word', 'surface_transcription'):
            print('getting underlying and surface transcriptions')
            q = q.columns(
                    c.phone.word.transcription.column_name('word_underlying_transcription'),
                    c.phone.word.surface_transcription.column_name('word_surface_transcription'))

        if c.hierarchy.has_type_property('word', 'containsvowelobstruent'):
            q = q.columns(c.phone.word.containsvowelobstruent.column_name('word_containsvowelobstruent'))

        # get baseline duration:
        # for most corpora this should be done over words
        # as buckeye has many-to-one correspondence between transcriptions and words
        # buckeye should have duration calculated over its underlying transcription
        if baseline:
            if not c.hierarchy.has_type_property('word', 'baseline'):
                print('getting baseline from word')
                c.encode_baseline('word', 'duration')
                q = q.columns(c.phone.word.baseline_duration.column_name('word_baseline_duration'))

        ## Write the query to a CSV file
        print("Writing CSV")
        q.to_csv(csv_path)
        end = time.time()
        time_taken = time.time() - beg
        print('Query took: {}'.format(end - beg))
        print("Results for query written to " + csv_path)
        common.save_performance_benchmark(config, 'duration_export', time_taken)

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
        duration_export(config, corpus_name, corpus_conf['corpus_directory'], corpus_conf['dialect_code'], corpus_conf['speakers'], corpus_conf['vowel_inventory'], stressed_vowels=stressed_vowels, baseline = baseline, ignored_speakers=ignored_speakers)
        print('Finishing up!')
