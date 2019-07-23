import time
from datetime import datetime
import os
import sys

sys.path.insert(0, '/mnt/e/Dev/Polyglot/PolyglotDB')
import re
import yaml
import csv
import platform
import polyglotdb.io as pgio

from polyglotdb import CorpusContext
from polyglotdb.io.enrichment import enrich_speakers_from_csv, enrich_lexicon_from_csv
from polyglotdb.acoustics.formants.refined import analyze_formant_points_refinement
from polyglotdb.client.client import PGDBClient, ClientError

base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# =============== CONFIGURATION ===============

duration_threshold = 0.05
##### JM #####
# nIterations = 1
nIterations = 20
##############
base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sibilant_script_path = os.path.join(base_dir, 'Common', 'sibilant_jane_optimized.praat')

# =============================================
now = datetime.now()
date = '{}-{}-{}'.format(now.year, now.month, now.day)


def load_token():
    token_path = os.path.join(base_dir, 'auth_token')
    if not os.path.exists(token_path):
        return None
    with open(token_path, 'r') as f:
        token = f.read().strip()
    return token


def save_performance_benchmark(config, task, time_taken):
    benchmark_folder = os.path.join(base_dir, 'benchmarks')
    os.makedirs(benchmark_folder, exist_ok=True)
    benchmark_file = os.path.join(benchmark_folder, 'benchmarks.csv')
    if not os.path.exists(benchmark_file):
        with open(benchmark_file, 'w', encoding='utf8') as f:
            writer = csv.writer(f, delimiter=',')
            writer.writerow(['Computer', 'Corpus', 'Date', 'Corpus_size', 'Task', 'Time'])
    with open(benchmark_file, 'a', encoding='utf8') as f:
        writer = csv.writer(f, delimiter=',')
        writer.writerow([platform.node(), config.corpus_name, date, get_size_of_corpus(config), task, time_taken])


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


def call_back(*args):
    args = [x for x in args if isinstance(x, str)]
    if args:
        print(' '.join(args))


def reset(config):
    with CorpusContext(config) as c:
        print('Resetting the corpus.')
        c.reset()


def loading(config, corpus_dir, textgrid_format):
    with CorpusContext(config) as c:
        exists = c.exists()
    if exists:
        print('Corpus already loaded, skipping import.')
        return
    if not os.path.exists(corpus_dir):
        print('The path {} does not exist.'.format(corpus_dir))
        sys.exit(1)
    textgrid_format = textgrid_format.upper()
    with CorpusContext(config) as c:
        print('loading')

        if textgrid_format in ["BUCKEYE", "B"]:
            parser = pgio.inspect_buckeye(corpus_dir)
        elif textgrid_format == "CSV":
            parser = pgio.inspect_buckeye(corpus_dir)
        elif textgrid_format.lower() in ["FAVE", "F"]:
            parser = pgio.inspect_fave(corpus_dir)
        elif textgrid_format == "ILG":
            parser = pgio.inspect_ilg(corpus_dir)
        elif textgrid_format in ["LABBCAT", "L"]:
            parser = pgio.inspect_labbcat(corpus_dir)
        elif textgrid_format in ["P", "PARTITUR"]:
            parser = pgio.inspect_partitur(corpus_dir)
        elif textgrid_format in ["MAUS", "W"]:
            parser = pgio.inspect_maus(corpus_dir)
        elif textgrid_format in ["TIMIT", "T"]:
            parser = pgio.inspect_timit(corpus_dir)
        elif textgrid_format in ["W", "maus"]:
            parser = pgio.inspect_maus(corpus_dir)
        else:
            parser = pgio.inspect_mfa(corpus_dir)
        parser.call_back = call_back
        beg = time.time()
        c.load(parser, corpus_dir)
        end = time.time()
        time_taken = end - beg
        print('Loading took: {}'.format(time_taken))
    save_performance_benchmark(config, 'import', time_taken)


def basic_enrichment(config, syllabics, pauses):
    with CorpusContext(config) as g:
        if not 'utterance' in g.annotation_types:
            print('encoding utterances')
            begin = time.time()
            g.encode_pauses(pauses)
            # g.encode_pauses('^[<{].*$', call_back = call_back)
            g.encode_utterances(min_pause_length=0.15)  # , call_back = call_back)
            # g.encode_utterances(min_pause_length = 0.5, call_back = call_back)
            time_taken = time.time() - begin
            print('Utterance enrichment took: {}'.format(time_taken))
            save_performance_benchmark(config, 'utterance_encoding', time_taken)

        if syllabics and 'syllable' not in g.annotation_types:
            print('encoding syllables')
            begin = time.time()
            g.encode_syllabic_segments(syllabics)
            g.encode_syllables('maxonset')
            time_taken = time.time() - begin
            print('Syllable enrichment took: {}'.format(time.time() - begin))
            save_performance_benchmark(config, 'syllable_encoding', time_taken)

        print('enriching utterances')
        if syllabics and not g.hierarchy.has_token_property('utterance', 'speech_rate'):
            begin = time.time()
            g.encode_rate('utterance', 'syllable', 'speech_rate')
            time_taken = time.time() - begin
            print('Speech rate encoding took: {}'.format(time.time() - begin))
            save_performance_benchmark(config, 'speech_rate_encoding', time_taken)

        if not g.hierarchy.has_token_property('utterance', 'num_words'):
            begin = time.time()
            g.encode_count('utterance', 'word', 'num_words')
            time_taken = time.time() - begin
            print('Word count encoding took: {}'.format(time.time() - begin))
            save_performance_benchmark(config, 'num_words_encoding', time_taken)

        if syllabics and not g.hierarchy.has_token_property('utterance', 'num_syllables'):
            begin = time.time()
            g.encode_count('utterance', 'syllable', 'num_syllables')
            time_taken = time.time() - begin
            print('Syllable count encoding took: {}'.format(time.time() - begin))
            save_performance_benchmark(config, 'num_syllables_encoding', time_taken)

        if syllabics and not g.hierarchy.has_token_property('syllable', 'position_in_word'):
            print('enriching syllables')
            begin = time.time()
            g.encode_position('word', 'syllable', 'position_in_word')
            time_taken = time.time() - begin
            print('Syllable position encoding took: {}'.format(time.time() - begin))
            save_performance_benchmark(config, 'position_in_word_encoding', time_taken)

        if syllabics and not g.hierarchy.has_token_property('syllable', 'num_phones'):
            begin = time.time()
            g.encode_count('syllable', 'phone', 'num_phones')
            time_taken = time.time() - begin
            print('Phone count encoding took: {}'.format(time.time() - begin))
            save_performance_benchmark(config, 'num_phones_encoding', time_taken)

        # print('enriching words')
        # if not g.hierarchy.has_token_property('word', 'position_in_utterance'):
        #    begin = time.time()
        #    g.encode_position('utterance', 'word', 'position_in_utterance')
        #    print('Utterance position encoding took: {}'.format(time.time() - begin))

        if syllabics and not g.hierarchy.has_token_property('word', 'num_syllables'):
            begin = time.time()
            g.encode_count('word', 'syllable', 'num_syllables')
            time_taken = time.time() - begin
            print('Syllable count encoding took: {}'.format(time.time() - begin))
            save_performance_benchmark(config, 'num_syllables_encoding', time_taken)

        print('enriching syllables')
        if syllabics and g.hierarchy.has_type_property('word', 'stresspattern') and not g.hierarchy.has_token_property(
                'syllable',
                'stress'):
            begin = time.time()
            g.encode_stress_from_word_property('stresspattern')
            time_taken = time.time() - begin
            print("encoded stress")
            save_performance_benchmark(config, 'stress_encoding_from_pattern', time_taken)
        elif syllabics and re.search(r"\d", syllabics[0]) and not g.hierarchy.has_type_property('syllable',
                                                                                                'stress'):  # If stress is included in the vowels
            begin = time.time()
            g.encode_stress_to_syllables("[0-9]", clean_phone_label=False)
            time_taken = time.time() - begin
            print("encoded stress")
            save_performance_benchmark(config, 'stress_encoding', time_taken)


def lexicon_enrichment(config, unisyn_spade_directory, dialect_code):
    enrichment_dir = os.path.join(unisyn_spade_directory, 'enrichment_files')
    if not os.path.exists(enrichment_dir):
        print('Could not find enrichment_files directory from {}, skipping lexical enrichment.'.format(
            unisyn_spade_directory))
        return
    with CorpusContext(config) as g:

        for lf in os.listdir(enrichment_dir):
            path = os.path.join(enrichment_dir, lf)
            if lf == 'rule_applications.csv':
                if g.hierarchy.has_type_property('word', 'UnisynPrimStressedVowel1'.lower()):
                    print('Dialect independent enrichment already loaded, skipping.')
                    continue
            elif lf.startswith(dialect_code):
                if g.hierarchy.has_type_property('word', 'UnisynPrimStressedVowel2_{}'.format(
                        dialect_code).lower()):
                    print('Dialect specific enrichment already loaded, skipping.')
                    continue
            else:
                continue
            begin = time.time()
            enrich_lexicon_from_csv(g, path)
            time_taken = time.time() - begin
            print('Lexicon enrichment took: {}'.format(time.time() - begin))
            save_performance_benchmark(config, 'lexicon_enrichment', time_taken)


def speaker_enrichment(config, speaker_file):
    if not os.path.exists(speaker_file):
        print('Could not find {}, skipping speaker enrichment.'.format(speaker_file))
        return
    with CorpusContext(config) as g:
        if not g.hierarchy.has_speaker_property('gender'):
            begin = time.time()
            enrich_speakers_from_csv(g, speaker_file)
            time_taken = time.time() - begin
            print('Speaker enrichment took: {}'.format(time.time() - begin))
            save_performance_benchmark(config, 'speaker_enrichment', time_taken)
        else:
            print('Speaker enrichment already done, skipping.')


def sibilant_acoustic_analysis(config, sibilant_segments, ignored_speakers=None):
    # Encode sibilant class and analyze sibilants using the praat script
    with CorpusContext(config) as c:
        if c.hierarchy.has_token_property('phone', 'cog'):
            print('Sibilant acoustics already analyzed, skipping.')
            return
        print('Beginning sibilant analysis')
        beg = time.time()
        if ignored_speakers:
            q = c.query_graph(c.phone).filter(c.phone.label.in_(sibilant_segments))
            q = q.filter(c.phone.speaker.name.not_in_(ignored_speakers))
            q = q.filter(c.phone.duration > 0.01)
            q.create_subset("sibilant")
        else:
            c.encode_class(sibilant_segments, 'sibilant')
        time_taken = time.time() - beg
        save_performance_benchmark(config, 'sibilant_encoding', time_taken)
        print('sibilants encoded')

        # analyze all sibilants using the script found at script_path
        beg = time.time()
        c.analyze_script(annotation_type='phone', subset='sibilant', script_path=sibilant_script_path, duration_threshold=0.01)
        end = time.time()
        time_taken = time.time() - beg
        print('Sibilant analysis took: {}'.format(end - beg))
        save_performance_benchmark(config, 'sibilant_acoustic_analysis', time_taken)


def formant_acoustic_analysis(config, vowels, vowel_prototypes_path, ignored_speakers=None, drop_formant=False, output_tracks = False, subset="vowel", reset_formants=False):
    with CorpusContext(config) as c:
        if vowels is not None:
            if ignored_speakers:
                q = c.query_graph(c.phone).filter(c.phone.label.in_(vowels))
                q = q.filter(c.phone.speaker.name.not_in_(ignored_speakers))
                q = q.filter(c.phone.duration > 0.01)
                q.create_subset(subset)
            else:
                c.encode_class(vowels, subset)
        if not reset_formants and not output_tracks and c.hierarchy.has_token_property('phone', 'F1'):
            print('Formant point analysis already done, skipping.')
            return
        elif not reset_formants and output_tracks and 'formants' in c.hierarchy.acoustics:
            print('Formant track analysis already done, skipping.')
            return
        print('Beginning formant analysis')
        beg = time.time()
        time_taken = time.time() - beg
        save_performance_benchmark(config, 'vowel_encoding', time_taken)
        print('vowels encoded')
        beg = time.time()
        metadata = analyze_formant_points_refinement(c, subset, duration_threshold=duration_threshold,
                                                     num_iterations=nIterations,
                                                     vowel_prototypes_path=vowel_prototypes_path,
                                                     drop_formant=drop_formant,
                                                     output_tracks = output_tracks
                                                     )
        end = time.time()
        time_taken = time.time() - beg
        print('Analyzing formants took: {}'.format(end - beg))
        save_performance_benchmark(config, 'formant_acoustic_analysis', time_taken)


def formant_export(config, corpus_name, dialect_code, speakers, vowels, ignored_speakers=None, output_tracks=True):  # Gets information into a csv

    if output_tracks:
        csv_path = os.path.join(base_dir, corpus_name, '{}_formant_tracks.csv'.format(corpus_name))
    else:
        csv_path = os.path.join(base_dir, corpus_name, '{}_formants.csv'.format(corpus_name))
    # Unisyn columns
    other_vowel_codes = ['unisynPrimStressedVowel2_{}'.format(dialect_code),
                         'UnisynPrimStressedVowel3_{}'.format(dialect_code),
                         'UnisynPrimStressedVowel3_XSAMPA',
                         'AnyRuleApplied_{}'.format(dialect_code)]

    with CorpusContext(config) as c:
        print('Beginning formant export')
        beg = time.time()
        q = c.query_graph(c.phone)
        if speakers:
            q = q.filter(c.phone.speaker.name.in_(speakers))
        if ignored_speakers:
            q = q.filter(c.phone.speaker.name.not_in_(ignored_speakers))
        q = q.filter(c.phone.label.in_(vowels))
        if output_tracks:
            q = q.columns(c.phone.speaker.name.column_name('speaker'), c.phone.discourse.name.column_name('discourse'),
                          c.phone.id.column_name('phone_id'), c.phone.label.column_name('phone_label'),
                          c.phone.begin.column_name('begin'), c.phone.end.column_name('end'),
                          c.phone.duration.column_name('duration'),
                          c.phone.following.label.column_name('following_phone'),
                          c.phone.previous.label.column_name('previous_phone'), c.phone.word.label.column_name('word'),
                          c.phone.formants.track)
        else:
            q = q.columns(c.phone.speaker.name.column_name('speaker'), c.phone.discourse.name.column_name('discourse'),
                          c.phone.id.column_name('phone_id'), c.phone.label.column_name('phone_label'),
                          c.phone.begin.column_name('begin'), c.phone.end.column_name('end'),
                          c.phone.syllable.stress.column_name('syllable_stress'),
                          c.phone.syllable.word.stresspattern.column_name('word_stress_pattern'),
                          c.phone.syllable.position_in_word.column_name('syllable_position_in_word'),
                          c.phone.duration.column_name('duration'),
                          c.phone.following.label.column_name('following_phone'),
                          c.phone.previous.label.column_name('previous_phone'), c.phone.word.label.column_name('word'),
                          c.phone.F1.column_name('F1'), c.phone.F2.column_name('F2'), c.phone.F3.column_name('F3'),
                          c.phone.B1.column_name('B1'), c.phone.B2.column_name('B2'), c.phone.B3.column_name('B3'),
                          c.phone.A1.column_name('A1'), c.phone.A2.column_name('A2'), c.phone.A3.column_name('A3'), c.phone.Ax.column_name('Ax'), c.phone.num_formants.column_name('num_formants'), c.phone.drop_formant.column_name('drop_formant'))
        if c.hierarchy.has_type_property('word', 'UnisynPrimStressedVowel1'.lower()):
            q = q.columns(c.phone.word.unisynprimstressedvowel1.column_name('UnisynPrimStressedVowel1'))
        for v in other_vowel_codes:
            if c.hierarchy.has_type_property('word', v.lower()):
                q = q.columns(getattr(c.phone.word, v.lower()).column_name(v))
        for sp, _ in c.hierarchy.speaker_properties:
            if sp == 'name':
                continue
            q = q.columns(getattr(c.phone.speaker, sp).column_name(sp))
        q.to_csv(csv_path)
        end = time.time()
        time_taken = time.time() - beg
        print('Query took: {}'.format(end - beg))
        print("Results for query written to " + csv_path)
        save_performance_benchmark(config, 'formant_export', time_taken)


def sibilant_export(config, corpus_name, dialect_code, speakers, ignored_speakers=None):
    csv_path = os.path.join(base_dir, corpus_name, '{}_sibilants.csv'.format(corpus_name))
    with CorpusContext(config) as c:
        # export to CSV all the measures taken by the script, along with a variety of data about each phone
        print("Beginning sibilant export")
        beg = time.time()
        q = c.query_graph(c.phone).filter(c.phone.subset == 'sibilant')
        q = q.filter(c.phone.begin == c.phone.syllable.word.begin)
        if speakers:
            q = q.filter(c.phone.speaker.name.in_(speakers))
        if ignored_speakers:
            q = q.filter(c.phone.speaker.name.not_in_(ignored_speakers))
        # qr = c.query_graph(c.phone).filter(c.phone.subset == 'sibilant')
        # this exports data for all sibilants
        qr = q.columns(c.phone.speaker.name.column_name('speaker'),
                       c.phone.discourse.name.column_name('discourse'),
                       c.phone.id.column_name('phone_id'), c.phone.label.column_name('phone_label'),
                       c.phone.begin.column_name('phone_begin'), c.phone.end.column_name('phone_end'),
                       c.phone.duration.column_name('duration'),
                       # c.phone.syllable.position_in_word.column_name('syllable_position_in_word'),
                       c.phone.following.label.column_name('following_phone'),
                       c.phone.previous.label.column_name('previous_phone'),
                       c.phone.syllable.word.label.column_name('word'),
                       c.phone.syllable.word.id.column_name('word_id'),
                       c.phone.syllable.stress.column_name('syllable_stress'),
                       c.phone.syllable.phone.filter_by_subset('onset').label.column_name('onset'),
                       c.phone.syllable.phone.filter_by_subset('nucleus').label.column_name('nucleus'),
                       c.phone.syllable.phone.filter_by_subset('coda').label.column_name('coda'),
                       c.phone.cog.column_name('cog'), c.phone.peak.column_name('peak'),
                       c.phone.slope.column_name('slope'), c.phone.spread.column_name('spread'))
        for sp, _ in c.hierarchy.speaker_properties:
            if sp == 'name':
                continue
            q = q.columns(getattr(c.phone.speaker, sp).column_name(sp))

        if c.hierarchy.has_token_property('word', 'surface_transcription'):
            print('getting underlying and surface transcriptions')
            q = q.columns(
                    c.phone.word.transcription.column_name('word_underlying_transcription'),
                    c.phone.word.surface_transcription.column_name('word_surface_transcription'))

        qr.to_csv(csv_path)
        end = time.time()
        time_taken = time.time() - beg
        print('Query took: {}'.format(end - beg))
        print("Results for query written to " + csv_path)
        save_performance_benchmark(config, 'sibilant_export', time_taken)

def polysyllabic_export(config, corpus_name, dialect_code, speakers):
    csv_path = os.path.join(base_dir, corpus_name, '{}_polysyllabic.csv'.format(corpus_name))
    with CorpusContext(config) as c:

        print("Beginning polysyllabic export")
        beg = time.time()
        q = c.query_graph(c.syllable)
        q = q.filter(c.syllable.word.end == c.syllable.word.utterance.end)
        q = q.filter(c.syllable.begin == c.syllable.word.begin)
        if speakers:
            q = q.filter(c.phone.speaker.name.in_(speakers))

        qr = q.columns(c.syllable.speaker.name.column_name('speaker'),
                       c.syllable.label.column_name('syllable_label'),
                       c.syllable.duration.column_name('syllable_duration'),
                       c.syllable.word.label.column_name('word'),
                       c.syllable.word.stresspattern.column_name('stress_pattern'),
                       c.syllable.word.num_syllables.column_name('num_syllables'))
        for sp, _ in c.hierarchy.speaker_properties:
            if sp == 'name':
                continue
            q = q.columns(getattr(c.syllable.speaker, sp).column_name(sp))

        qr.to_csv(csv_path)
        end = time.time()
        time_taken = time.time() - beg
        print('Query took: {}'.format(end - beg))
        print("Results for query written to " + csv_path)
        save_performance_benchmark(config, 'polysyllabic_export', time_taken)

def get_size_of_corpus(config):
    from polyglotdb.query.base.func import Sum
    with CorpusContext(config) as c:
        c.config.query_behavior = 'other'
        if 'utterance' not in c.annotation_types:
            q = c.query_graph(c.word).columns(Sum(c.word.duration).column_name('result'))
        else:
            q = c.query_graph(c.utterance).columns(Sum(c.utterance.duration).column_name('result'))
        results = q.all()
    return results[0]['result']

def check_database(corpus_name, token = load_token(), port = 8080):
    host = 'http://localhost:{}'.format(port)
    client = PGDBClient(host, token)
    try:
        client.start_database(corpus_name)
    except Exception as e:
        print("Database problem: {}".format(e))

def basic_queries(config):
    from polyglotdb.query.base.func import Sum
    with CorpusContext(config) as c:
        print(c.hierarchy)
        print('beginning basic queries')
        beg = time.time()
        q = c.query_lexicon(c.lexicon_phone).columns(c.lexicon_phone.label.column_name('label'))
        results = q.all()
        print('The phone inventory is:', ', '.join(sorted(x['label'] for x in results)))
        for r in results:
            total_count = c.query_graph(c.phone).filter(c.phone.label == r['label']).count()
            duration_threshold_count = c.query_graph(c.phone).filter(c.phone.label == r['label']).filter(
                c.phone.duration >= duration_threshold).count()
            qr = c.query_graph(c.phone).filter(c.phone.label == r['label']).limit(1)
            qr = qr.columns(c.phone.word.label.column_name('word'),
                            c.phone.word.transcription.column_name('transcription'))
            res = qr.all()
            if len(res) == 0:
                print('An example for {} was not found.'.format(r['label']))
            else:
                res = res[0]
                print('An example for {} (of {}, {} above {}) is the word "{}" with the transcription [{}]'.format(
                    r['label'], total_count, duration_threshold_count, duration_threshold, res['word'],
                    res['transcription']))

        q = c.query_speakers().columns(c.speaker.name.column_name('name'))
        results = q.all()
        print('The speakers in the corpus are:', ', '.join(sorted(x['name'] for x in results)))
        c.config.query_behavior = 'other'
        q = c.query_graph(c.utterance).columns(Sum(c.utterance.duration).column_name('result'))
        results = q.all()
        q = c.query_graph(c.word).columns(Sum(c.word.duration).column_name('result'))
        word_results = q.all()
        print('The total length of speech in the corpus is: {} seconds (utterances) {} seconds (words'.format(
            results[0]['result'], word_results[0]['result']))
        time_taken = time.time() - beg
        save_performance_benchmark(config, 'basic_query', time_taken)


def basic_size_queries(config):
    from statistics import mean
    import datetime
    from polyglotdb.query.base.func import Sum, Count
    with CorpusContext(config) as c:
        print('beginning size queries')
        speaker_q = c.query_speakers().columns(c.speaker.name.column_name('name'), Count(c.speaker.discourses.name).column_name('num_discourses'))

        average_num_discourses = mean(x['num_discourses'] for x in speaker_q.all())
        discourse_q = c.query_discourses().columns(c.discourse.name.column_name('name'), c.discourse.duration.column_name('duration'), Count(c.discourse.speakers.name).column_name('num_speakers'))
        average_duration = mean(x['duration'] for x in discourse_q.all() if x['duration'] is not None)
        average_num_speakers = mean(x['num_speakers'] for x in discourse_q.all())
        speaker_word_counts = []
        for s in c.speakers:
            q = c.query_graph(c.word).filter(c.word.speaker.name == s)
            speaker_word_counts.append(q.count())
        discourse_word_counts = []
        for d in c.discourses:
            q = c.query_graph(c.word).filter(c.word.discourse.name == d)
            discourse_word_counts.append(q.count())
        print('')
        print('')
        print('There are {} speakers and {} discourses in the corpus.'.format(speaker_q.count(), discourse_q.count()))
        print('The average duration of discourses is {}.'.format(datetime.timedelta(seconds=average_duration)))
        print('The average number of words per speaker is {} and speakers speak in {} discourses on average.'.format(mean(speaker_word_counts), average_num_discourses))
        print('The average number of words per discourse is {} and have {} speakers on average.'.format(mean(discourse_word_counts), average_num_speakers))
