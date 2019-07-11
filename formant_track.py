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

def formant_track_export(config, corpus_name, corpus_directory, dialect_code, speakers, vowel_prototypes_path):
    csv_path = os.path.join(base_dir, corpus_name, '{}_formant_tracks.csv'.format(corpus_name))

    vowels_to_analyze = ['oi']
    print("Processing formant tracks for {}".format(corpus_name))
    beg = time.time()

    with CorpusContext(config) as c:
        if c.hierarchy.has_type_property('word', 'unisynprimstressedvowel1'):
            q = c.query_graph(c.phone)
            q = q.filter(c.phone.syllable.stress == '1')
            q = q.filter(c.phone.subset == 'nucleus')
            q = q.filter(c.phone.syllable.word.unisynprimstressedvowel1.in_(vowels_to_analyze))
            q.create_subset("unisyn_subset")
            print('susbet took {}'.format(time.time()-beg))

        else:
            print('{} has not been enriched with Unisyn information.'.format(corpus_name))
            return

    print('Beginning formant calculation')
    common.formant_acoustic_analysis(config, None, vowel_prototypes_path, drop_formant = drop_formant, output_tracks = True, subset="unisyn_subset")

    with CorpusContext(config) as c:
        print('Beginning formant export')
        q = c.query_graph(c.phone)
        q = q.filter(c.phone.subset == 'unisyn_subset')

        if speakers:
            q = q.filter(c.phone.speaker.name.in_(speakers))

        print(c.hierarchy.acoustics)
        print('Applied filters')
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
                      c.phone.formants.track)
        for sp, _ in c.hierarchy.speaker_properties:
            if sp == 'name':
                continue
            q = q.columns(getattr(c.phone.speaker, sp).column_name(sp))
        print(c.hierarchy)
        print("Writing CSV")
        print(q)
        q.to_csv(csv_path)
        end = time.time()
        time_taken = time.time() - beg
        print('Query took: {}'.format(end - beg))
        print("Results for query written to {}".format(csv_path))
        common.save_performance_benchmark(config, 'formant_tracks_export', time_taken)


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
    print('Processing...')
    with ensure_local_database_running(corpus_name, port=8080, token=common.load_token()) as params:
        print(params)
        config = CorpusConfig(corpus_name, **params)
        config.formant_source = 'praat'
        # Common set up
        if reset:
            common.reset(config)
        
        common.loading(config, corpus_conf['corpus_directory'], corpus_conf['input_format'])

        common.lexicon_enrichment(config, corpus_conf['unisyn_spade_directory'], corpus_conf['dialect_code'])
        common.speaker_enrichment(config, corpus_conf['speaker_enrichment_file'])

        common.basic_enrichment(config, corpus_conf['vowel_inventory'] + corpus_conf['extra_syllabic_segments'], corpus_conf['pauses'])

        vowel_prototypes_path = corpus_conf.get('vowel_prototypes_path','')
        if not vowel_prototypes_path:
            vowel_prototypes_path = os.path.join(base_dir, corpus_name, '{}_prototypes.csv'.format(corpus_name))

        formant_track_export(config, corpus_name, corpus_conf['corpus_directory'], corpus_conf['dialect_code'],
                              corpus_conf['speakers'], vowel_prototypes_path = vowel_prototypes_path)
        print('Finishing up!')
