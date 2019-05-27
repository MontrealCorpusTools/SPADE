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

def duration_export(config, corpus_name, dialect_code, speakers, vowels):
    csv_path = os.path.join(base_dir, corpus_name, '{}_duration.csv'.format(corpus_name))
    with CorpusContext(config) as c:

        print("Beginning duration export")
        beg = time.time()

        consonants = ['p', 'P', 't', 'T', 'k', 'K', 'b', 'B', 'd', 'D', 'g', 'G',
                      'F', 'f', 'V', 'v', 'N', 'n', 'm', 'M', 'NG', 'TH', 'DH',
                      'l', 'L', 'ZH', 'x', 'X', 'r', 'R', 's', 'S', 'sh', 'SH',
                      'z','Z', 'zh', 'ZH']
        q = c.query_graph(c.phone).filter(c.phone.label.in_(vowels))
        q = q.filter(c.phone.following.end == c.phone.syllable.end)
        q = q.filter(c.phone.following.end == c.phone.word.utterance.end)
        q = q.filter(c.phone.following.label.in_(consonants))
        q = q.filter(c.phone.word.num_syllables == 1)
        if speakers:
            q = q.filter(c.phone.speaker.name.in_(speakers))

        print("Applied filters")
        q = q.columns(c.phone.label.column_name('phone_label'),
                      c.phone.begin.column_name('phone_begin'),
                      c.phone.end.column_name('phone_end'),
                      c.phone.duration.column_name('phone_duration'),
                      c.phone.previous.label.column_name('previous_phone'),
                      c.phone.following.label.column_name('following_phone'),
                      c.phone.word.unisynprimstressedvowel1.column_name('word_unisyn'),
                      c.phone.word.label.column_name('word_label'),
                      c.phone.word.begin.column_name('word_begin'),
                      c.phone.syllable.label.column_name('syllable_label'),
                      c.phone.syllable.duration.column_name('syllable_duration'),
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

        print("Writing CSV")
        q.to_csv(csv_path)
        end = time.time()
        time_taken = time.time() - beg
        print('Query took: {}'.format(end - beg))
        print("Results for query written to " + csv_path)
        common.save_performance_benchmark(config, 'duration_export', time_taken)

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
        config = CorpusConfig(corpus_name, **params)
        config.formant_source = 'praat'
        # Common set up
        if reset:
            common.reset(config)
        common.loading(config, corpus_conf['corpus_directory'], corpus_conf['input_format'])

        common.lexicon_enrichment(config, corpus_conf['unisyn_spade_directory'], corpus_conf['dialect_code'])
        common.speaker_enrichment(config, corpus_conf['speaker_enrichment_file'])

        common.basic_enrichment(config, corpus_conf['vowel_inventory'] + corpus_conf['extra_syllabic_segments'], corpus_conf['pauses'])

        duration_export(config, corpus_name, corpus_conf['dialect_code'], corpus_conf['speakers'], corpus_conf['vowel_inventory'])
        print('Finishing up!')
