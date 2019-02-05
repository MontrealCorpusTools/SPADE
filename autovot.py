import sys
import os
import argparse

import sys
import yaml
base_dir = os.path.dirname(os.path.abspath(__file__))
import polyglotdb.io as pgio
from polyglotdb.utils import ensure_local_database_running
from polyglotdb.config import CorpusConfig
from polyglotdb import CorpusContext

from Common import common

def load_config(corpus_name):
    path = os.path.join(base_dir, corpus_name, '{}.yaml'.format(corpus_name))
    if not os.path.exists(path):
        print('The config file for the specified corpus does not exist ({}).'.format(path))
        sys.exit(1)
    expected_keys = ['corpus_directory', 'input_format', 'dialect_code', 'unisyn_spade_directory',
                     'speaker_enrichment_file',
                     'speakers', 'vowel_inventory', 'stressed_vowels', 'sibilant_segments'
                     ]
    with open(path, 'r', encoding='utf8') as f:
        conf = yaml.load(f)
    missing_keys = []
    for k in expected_keys:
        if k not in conf:
            missing_keys.append(k)

    ##### JM #####
    if not 'vowel_prototypes_path' in conf:
        conf['vowel_prototypes_path'] = ''
        print('no vowel prototypes path given, so using no prototypes')
    elif not os.path.exists(conf['vowel_prototypes_path']):
        conf['vowel_prototypes_path'] = ''
        print('vowel prototypes path not valid, so using no prototypes')
    ##############

    if missing_keys:
        print('The following keys were missing from {}: {}'.format(path, ', '.join(missing_keys)))
        sys.exit(1)
    return conf

def loading(config, corpus_dir, textgrid_format):
    with CorpusContext(config) as c:
        exists = c.exists()
    if exists:
        print('Corpus already loaded, skipping import.')
        return
    if not os.path.exists(corpus_dir):
        print('The path {} does not exist.'.format(corpus_dir))
        sys.exit(1)
    with CorpusContext(config) as c:
        print('loading')

        if textgrid_format == "buckeye":
            parser = pgio.inspect_buckeye(corpus_dir)
        elif textgrid_format == "csv":
            parser = pgio.inspect_buckeye(corpus_dir)
        elif textgrid_format.lower() == "fave":
            parser = pgio.inspect_fave(corpus_dir)
        elif textgrid_format == "ilg":
            parser = pgio.inspect_ilg(corpus_dir)
        elif textgrid_format == "labbcat":
            parser = pgio.inspect_labbcat(corpus_dir)
        elif textgrid_format == "partitur":
            parser = pgio.inspect_partitur(corpus_dir)
        elif textgrid_format == "timit":
            parser = pgio.inspect_timit(corpus_dir)
        else:
            parser = pgio.inspect_mfa(corpus_dir)
        c.load(parser, corpus_dir)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('corpus_name', help='Name of the corpus')
    parser.add_argument('classifier', help='Path to classifier')
    parser.add_argument('-r', '--reset', help="Reset the corpus", action='store_true')
    parser.add_argument("-e", "--export_file", help='Path of CSV to export')

    args = parser.parse_args()
    corpus_name = args.corpus_name
    classifier = args.classifier
    reset = args.reset
    directories = [x for x in os.listdir(base_dir) if os.path.isdir(x) and x != 'Common']

    if args.corpus_name not in directories:
        print(
            'The corpus {0} does not have a directory (available: {1}).  Please make it with a {0}.yaml file inside.'.format(
                args.corpus_name, ', '.join(directories)))
        sys.exit(1)
    
    corpus_conf = load_config(corpus_name)

    print('Processing...')
    #Connect to local database at 8080
    with ensure_local_database_running(corpus_name, port=8080, token = common.load_token()) as params:
        #Load corpus context and config info
        config = CorpusConfig(corpus_name, **params)
        config.formant_source = 'praat'
        # Common set up
        if reset:
            with CorpusContext(config) as c:
                print("Resetting the corpus.")
                c.reset()
        loading(config, corpus_conf['corpus_directory'], corpus_conf['input_format'])

        with CorpusContext(config) as g:
            g.reset_vot()

            small_speakers = ['Adam', 'Norman', 'Raymond_Lafleur']
            stops = ['P', 'T', 'K']

            #If there is already a stop subset in the database, delete it
            if g.hierarchy.has_token_subset('phone', "stops"):
                g.query_graph(g.phone).remove_subset("stops")

            #Encode a subset of word initial stops spoken by a speaker in small_speakers
            q = g.query_graph(g.phone)
            #q = q.filter(g.phone.speaker.name.in_(small_speakers)).filter(g.phone.begin==g.phone.word.begin).filter(g.phone.label.in_(stops))
            q = q.filter(g.phone.begin==g.phone.word.begin).filter(g.phone.label.in_(stops))
            q.create_subset('stops')

            #Ensure utterances are encoded and encoded them if not.
            if not 'utterance' in g.annotation_types:
                g.encode_pauses(corpus_conf["pauses"])
                g.encode_utterances(min_pause_length=0.15)

            g.analyze_vot(stop_label='stops',
                        classifier=classifier,
                        vot_min=15,
                        vot_max=250,
                        window_min=-30,
                        window_max=30)

            #Get a query of necessary info
            q = g.query_graph(g.phone).filter(g.phone.subset == "stops").columns(g.phone.label, \
                    g.phone.begin, g.phone.end, g.phone.vot.confidence, \
                    g.phone.vot.begin, g.phone.vot.end, g.phone.word.label,\
                    g.phone.discourse.name, g.phone.speaker.name).order_by(g.phone.begin)

            if args.export_file:
                q.to_csv(args.export_file)
            else:
                q.to_csv(os.path.join(base_dir, corpus_name, '{}_vot.csv'.format(corpus_name)))
