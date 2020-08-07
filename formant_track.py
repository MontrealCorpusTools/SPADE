#########################################
## SPADE formant track analysis script ##
#########################################

## Processes and analyses multi-point 'tracks' of formant values, along with linguistics
## and acoustic information from corpora collected as part of the SPeech Acros Dialects
## of English (SPADE) project.

## Input:
## - corpus name (e.g., Buckeye, SOTC)
## - corpus metadata (stored in a YAML file)
##   this file should specify the path to the
##   audio, transcripts, metadata files (e.g.,
##   speaker, lexicon), and a datafile containing
##   prototype formant values to be used for
##   formant estimation
## Output:
## - CSV of multi-point vowel measurements
##   (default: 21 rows per token; 1 row per formant
##   point sampled), with columns for the linguistic,
##   acoustic, and speaker information associated
##   with that token

import re
import sys
import os
import argparse
import time

base_dir = os.path.dirname(os.path.abspath(__file__))
script_dir = os.path.join(base_dir, 'Common')

sys.path.insert(0, script_dir)

drop_formant = True

import common

from polyglotdb import CorpusContext
from polyglotdb.utils import ensure_local_database_running
from polyglotdb import CorpusConfig

def formant_track_export(config, corpus_name, corpus_directory, dialect_code, speakers, vowel_inventory, vowel_prototypes_path, reset_formants, vowel_subset, ignored_speakers = None):
    ## Main function for processing and generating formant tracks
    csv_path = os.path.join(base_dir, corpus_name, '{}_formant_tracks.csv'.format(corpus_name))

    ## Determine which vowels to apply over:
    ## if -s flag is used, the predefined vowel
    ## set will be analysed; otherwise, the list
    ## of vowels specfied in the YAML file will
    ## be analysed
    if vowel_subset:
        ## The default list of vowels to be analysed:
        ## TIDE (ae), PRICE (ai), WASTE (ee), WAIST (ei), FLEECE (ii),
        ## CHOICE (oi), GOAT (ou), KNOW (ouw), MOUTH (ow), GOOSE (uu)
        vowels_to_analyze = ['ae', 'ai', 'ee', 'ei', 'ii', 'oi', 'ou', 'ouw', 'ow', 'uu']
    else:
        vowels_to_analyze = vowel_inventory
    print("Processing formant tracks for {}".format(corpus_name))
    beg = time.time()

    ## Create the subset of corpus tokens that will be subject to
    ## formant track estimation
    with CorpusContext(config) as c:
        ## Check the corpus has been enriched with UNISYN information
        ## If so, restrict the subset to: the UNISYN vowels defined above,
        ## vowels with primary stress, those which form the nucleus of the
        ## syllable, and those with a duration of at least 50ms
        if c.hierarchy.has_type_property('word', 'unisynprimstressedvowel1'):
            q = c.query_graph(c.phone)
            q = q.filter(c.phone.syllable.stress == '1')
            q = q.filter(c.phone.subset == 'nucleus')
            q = q.filter(c.phone.syllable.word.unisynprimstressedvowel1.in_(vowels_to_analyze))
            if ignored_speakers:
                q = q.filter(c.phone.speaker.name.not_in_(ignored_speakers))
            q = q.filter(c.phone.duration >= 0.05)
            q.create_subset("unisyn_subset")
            print('subset took {}'.format(time.time() - beg))

        else:
            print('{} has not been enriched with Unisyn information.'.format(corpus_name))
            return

        ## If the -f flag has been used, previously-estimated
        ## formant values will be removed from the database,
        ## allowing formants to be re-estimated without needing
        ## to re-import the corpus
        if reset_formants:
            print("Resetting formants")
            c.reset_acoustics()
            print('Beginning formant calculation')

    ## Perform acoustic analysis on the defined subset, enriching the corpus
    ## with 21-point formant tracks for the tokens in the subset.
    ## See common.py for the details of this function.
    common.formant_acoustic_analysis(config, None, vowel_prototypes_path, drop_formant = drop_formant, output_tracks = True, subset="unisyn_subset")

    with CorpusContext(config) as c:
        print('Beginning formant export')
        ## Constrain the formant track query
        ## to vowels which were subject to
        ## formant estimation
        q = c.query_graph(c.phone)
        q = q.filter(c.phone.subset == 'unisyn_subset')

        if speakers:
            q = q.filter(c.phone.speaker.name.in_(speakers))
        q = q.filter(c.phone.duration >= 0.05)
        print('Applied filters')
        
        ## Define the columns to be included in the query
        ## Include the formant columns with 'relativised' time
        ## (i.e., as % through the vowel, e.g., 5%, 10%, etc).
        formants_prop = c.phone.formants
        formants_prop.relative_time = True
        formants_track = formants_prop.interpolated_track
        formants_track.num_points = 21

        ## Include columns for speaker and file metadata,
        ## phone information (label, duration), surrounding
        ## phonological environment, syllable information
        ## (e.g., stress), word information, and speech rate
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
                      formants_track)

        ## Get UNISYN postlexical rules for all vowels
        ## iterate through word-level attributes
        for prop in c.hierarchy.type_properties.items():
            if prop[0] == 'word':
                ## UNISYN postlex rules are pre-pended with
                ## 'do_', so look for attributes with this
                for attr in prop[1]:
                    r = re.findall('do_.*', attr[0])
                    ## Add those rules as columns
                    try:
                        rule = r[0]
                        if c.hierarchy.has_type_property('word', rule):
                            q = q.columns(getattr(c.phone.word, rule).column_name(rule))
                    except IndexError:
                        continue

        ## Get speaker metadata columns
        for sp, _ in c.hierarchy.speaker_properties:
            if sp == 'name':
                continue
            q = q.columns(getattr(c.phone.speaker, sp).column_name(sp))

        ## Get the phonological transcription labels if using the Buckeye corpus
        if c.hierarchy.has_token_property('word', 'surface_transcription'):
            print('getting underlying and surface transcriptions')
            q = q.columns(
                    c.phone.word.transcription.column_name('word_underlying_transcription'),
                    c.phone.word.surface_transcription.column_name('word_surface_transcription'))

        ## Export the query
        ## as a CSV
        print("Writing CSV")
        q.to_csv(csv_path)
        end = time.time()
        time_taken = time.time() - beg
        print('Query took: {}'.format(end - beg))
        print("Results for query written to {}".format(csv_path))
        common.save_performance_benchmark(config, 'formant_tracks_export', time_taken)

## Parse and process command line arguments
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('corpus_name', help='Name of the corpus')
    parser.add_argument('-r', '--reset', help="Reset the corpus", action='store_true')
    parser.add_argument('-f', '--formant_reset', help="Reset formant measures", action = 'store_true', default=False)
    parser.add_argument('-d', '--docker', help="This script is being called from Docker", action='store_true')
    parser.add_argument('-s', '--subset', help="Use pre-defined vowel subset versus vowels defined in config", action='store_true', default=False)

    args = parser.parse_args()
    corpus_name = args.corpus_name
    reset = args.reset
    docker = args.docker
    reset_formants = args.formant_reset
    vowel_subset = args.subset
    directories = [x for x in os.listdir(base_dir) if os.path.isdir(x) and x != 'Common']

    ## Check the corpus has a directory including
    ## a YAML file
    if args.corpus_name not in directories:
        print(
            'The corpus {0} does not have a directory (available: {1}).  Please make it with a {0}.yaml file inside.'.format(
                args.corpus_name, ', '.join(directories)))
        sys.exit(1)
    corpus_conf = common.load_config(corpus_name)
    print('Processing...')

    ignored_speakers = corpus_conf.get('ignore_speakers', [])
    if reset:
        common.reset(corpus_name)
    ip = common.server_ip
    if docker:
        ip = common.docker_ip
    with ensure_local_database_running(corpus_name, ip=ip, port=common.server_port, token=common.load_token()) as params:
        print(params)
        config = CorpusConfig(corpus_name, **params)
        config.formant_source = 'praat'
        # Common set up
        ## Check whether the corpus has already been imported (i.e., has a database file);
        ## if not, import the corpus using the audio and transcript files
        common.loading(config, corpus_conf['corpus_directory'], corpus_conf['input_format'])

        ## Add lexical, speaker, and linguistic/acoustic enrichments to the database
        common.lexicon_enrichment(config, corpus_conf['unisyn_spade_directory'], corpus_conf['dialect_code'])
        common.speaker_enrichment(config, corpus_conf['speaker_enrichment_file'])

        common.basic_enrichment(config, corpus_conf['vowel_inventory'] + corpus_conf['extra_syllabic_segments'], corpus_conf['pauses'])

        ## Check if the YAML contains a path to the vowel prototypes file;
        ## if not, use the default path (inside the corpus directory)
        vowel_prototypes_path = corpus_conf.get('vowel_prototypes_path','')
        if not vowel_prototypes_path:
            vowel_prototypes_path = os.path.join(base_dir, corpus_name, '{}_prototypes.csv'.format(corpus_name))

        ## Call formant track function defined above
        formant_track_export(config, corpus_name, corpus_conf['corpus_directory'], corpus_conf['dialect_code'],
                            corpus_conf['speakers'], corpus_conf['vowel_inventory'], vowel_prototypes_path = vowel_prototypes_path,
                            reset_formants = reset_formants, vowel_subset = vowel_subset, ignored_speakers = ignored_speakers)
        print('Finishing up!')
