###################################
## SPADE rhotics analysis script ##
###################################

## Processes and analyses linguistic and acoustic properties of
## word-final rhotics from corpora collected as part of The
## SPeech Across Dialects of English (SPADE) project

## Input:
## - corpus name (e.g., spade-Buckeye)
## - corpus metadata (in YAML file within the corpus directory

## Output:
## - CSV of measures for word-final rhotic segments

import sys
import os
import argparse
import time

base_dir = os.path.dirname(os.path.abspath(__file__))
script_dir = os.path.join(base_dir, 'Common')

sys.path.insert(0, script_dir)
# sys.path.insert(0, '/phon/MontrealCorpusTools/PolyglotDB/')

drop_formant = True

import common

from polyglotdb import CorpusContext
from polyglotdb.utils import ensure_local_database_running
from polyglotdb import CorpusConfig

def rhotics_export(config, corpus_name, corpus_directory, dialect_code, speakers, vowel_prototypes_path, reset_formants, ignored_speakers=None):
    csv_path = os.path.join(base_dir, corpus_name, '{}_rhotics.csv'.format(corpus_name))
    '''
    Main function for processing rhotics. Takes in corpus information and returns
    formant tracks, in the form of 21 equally-spaced points throughout the token
    (i.e. 5% intervals), meaning that 21 rows (observations) are returned for
    each rhotic token.

    The presence of rhotics is determined through corpus phone labels ('r') and
    UNISYN labels ('rhotics') associated with a token; be default, this function
    analyses only word-final rhotics in both monosyllabic and polysyllabic words.
    '''

    # list of unisyn vowels included in formant analysis
    rhotics = ['ar', 'or', 'our', '@r', 'aer', 'oir', 'owr', 'ir', 'er', 'eir', 'ur']
    r = ["r", "R", "r\\"]
    print("Processing formant tracks for {}".format(corpus_name))
    beg = time.time()

    with CorpusContext(config) as c:

        ## define the subset of tokens to be measured by formant tracking:
        ## these are rhotic tokens (determined by corpus and UNISYN labels)
        ## which are word-final and at least 50ms in duration
        if c.hierarchy.has_type_property('word', 'unisynprimstressedvowel1'):
            q = c.query_graph(c.phone)
            q = q.filter(c.phone.syllable.word.unisynprimstressedvowel1.in_(rhotics))
            q = q.filter(c.phone.end == c.phone.word.end)
            q = q.filter(c.phone.label.in_(r))
            if ignored_speakers:
                q = q.filter(c.phone.speaker.name.not_in_(ignored_speakers))
            q = q.filter(c.phone.duration >= 0.05)
            q.create_subset("unisyn_subset")
            print('subset took {}'.format(time.time() - beg))

        else:
            print('{} has not been enriched with Unisyn information.'.format(corpus_name))
            return

        ## reset the formant measures by using the -f flag:
        ## this is useful for experimenting with different
        ## formant tracking settings without needing to
        ## re-import the entire corpus
        if reset_formants:
            print("Resetting formants")
            c.reset_acoustics()
            print('Beginning formant calculation')

    ## perform formant tracking
    ## see common.py for how this is implemented
    common.formant_acoustic_analysis(config, None, vowel_prototypes_path, drop_formant = drop_formant, output_tracks = True, subset="unisyn_subset")

    with CorpusContext(config) as c:
        ## since the subsetting for measuring tokens
        ## and extracting them for output are separate,
        ## it is necessary to re-declare the subset of
        ## tokens to be included in the output
        print('Beginning formant export')
        q = c.query_graph(c.phone)
        q = q.filter(c.phone.subset == 'unisyn_subset')
        q = q.filter(c.phone.label.in_(r))
        q = q.filter(c.phone.end == c.phone.word.end)

        if speakers:
            q = q.filter(c.phone.speaker.name.in_(speakers))
        q = q.filter(c.phone.duration >= 0.05)
        print('Applied filters')

        ## define the properties of the formant track
        ## to be exported
        formants_prop = c.phone.formants
        formants_prop.relative_time = True
        formants_track = formants_prop.interpolated_track
        formants_track.num_points = 21

        ## define columns to be included in the output file
        ## these include information about the phone (segment
        ## label, start/end etc), surrounding segments, the
        ## syllable, the word, speaker properties, as well
        ## as acoustic information as speech rate
        q = q.columns(c.phone.speaker.name.column_name('speaker'),
                      c.phone.discourse.name.column_name('discourse'),
                      c.phone.id.column_name('phone_id'),
                      c.phone.label.column_name('phone_label'),
                      c.phone.begin.column_name('phone_begin'),
                      c.phone.end.column_name('phone_end'),
                      c.phone.duration.column_name('phone_duration'),
                      c.phone.syllable.stress.column_name('syllable_stress'),
                      c.phone.word.stresspattern.column_name('word_stresspattern'),
                      c.phone.syllable.position_in_word.column_name('syllable_position_in_word'),
                      c.phone.following.label.column_name('following_phone'),
                      c.phone.previous.label.column_name('previous_phone'),
                      c.phone.word.label.column_name('word_label'),
                      c.phone.word.unisynprimstressedvowel1.column_name('unisyn_vowel'),
                      c.phone.utterance.speech_rate.column_name('speech_rate'),
                      c.phone.syllable.label.column_name('syllable_label'),
                      c.phone.syllable.duration.column_name('syllable_duration'),
                      c.phone.syllable.begin.column_name('syllable_begin'),
                      c.phone.syllable.end.column_name('syllable_end'),
                      c.phone.word.duration.column_name('word_duration'),
                      c.phone.word.begin.column_name('word_begin'),
                      c.phone.word.end.column_name('word_end'),
                      c.phone.utterance.duration.column_name('utterance_duration'),
                      c.phone.utterance.begin.column_name('utterance_begin'),
                      c.phone.utterance.end.column_name('utterance_end'),
                      c.phone.word.transcription.column_name('word_transcription'),
                      c.phone.word.num_syllables.column_name('word_num_syllables'),
                      c.phone.utterance.num_syllables.column_name('utterance_num_syllables'),
                      c.phone.utterance.num_words.column_name('utterance_num_words'),
                      formants_track)
        for sp, _ in c.hierarchy.speaker_properties:
            if sp == 'name':
                continue
            q = q.columns(getattr(c.phone.speaker, sp).column_name(sp))

        ## Since the Buckeye corpus uses phonetic transcriptions by default,
        ## also extract the underlying (phonological) segment labels
        if c.hierarchy.has_token_property('word', 'surface_transcription'):
            print('getting underlying and surface transcriptions')
            q = q.columns(
                    c.phone.word.transcription.column_name('word_underlying_transcription'),
                    c.phone.word.surface_transcription.column_name('word_surface_transcription'))

        print("Writing CSV")
        q.to_csv(csv_path)
        end = time.time()
        time_taken = time.time() - beg
        print('Query took: {}'.format(end - beg))
        print("Results for query written to {}".format(csv_path))
        common.save_performance_benchmark(config, 'rhotics_export', time_taken)

## parse command-line arguments
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

    ## check the corpus has a metadata file
    if args.corpus_name not in directories:
        print(
            'The corpus {0} does not have a directory (available: {1}).  Please make it with a {0}.yaml file inside.'.format(
                args.corpus_name, ', '.join(directories)))
        sys.exit(1)
    corpus_conf = common.load_config(corpus_name)
    print('Processing...')

    ignored_speakers = corpus_conf.get('ignore_speakers', [])
    ## if the -r flag is used, the database information for the
    ## corpus will be deleted before the execution of the script
    if reset:
        common.reset(corpus_name)

    ## check status of the ISCAN server
    ip = common.server_ip
    if docker:
        ip = common.docker_ip
    with ensure_local_database_running(corpus_name, ip=ip, port=common.server_port, token=common.load_token()) as params:
        print(params)
        config = CorpusConfig(corpus_name, **params)
        config.formant_source = 'praat'
       
        ## add basic enrichments for the corpus, such as syllables, utterances,
        ## lexical and speaker information
        common.loading(config, corpus_conf['corpus_directory'], corpus_conf['input_format'])
        common.lexicon_enrichment(config, corpus_conf['unisyn_spade_directory'], corpus_conf['dialect_code'])
        common.speaker_enrichment(config, corpus_conf['speaker_enrichment_file'])
        common.basic_enrichment(config, corpus_conf['vowel_inventory'] + corpus_conf['extra_syllabic_segments'], corpus_conf['pauses'])

        ## check for the presence of vowel prototypes:
        ## this is not actively used for detecting formants,
        ## so this is skipped in measurement and speaker-level
        ## means are calculated at measurement-time
        vowel_prototypes_path = corpus_conf.get('vowel_prototypes_path','')
        if not vowel_prototypes_path:
            vowel_prototypes_path = os.path.join(base_dir, corpus_name, '{}_prototypes.csv'.format(corpus_name))

        ## call above-defined formant function
        ## and write export CSV file
        rhotics_export(config, corpus_name, corpus_conf['corpus_directory'], corpus_conf['dialect_code'],
                              corpus_conf['speakers'], vowel_prototypes_path = vowel_prototypes_path, reset_formants = reset_formants, ignored_speakers=ignored_speakers)
        print('Finishing up!')
