import time
import os
import sys
import re
import polyglotdb.io as pgio

from polyglotdb import CorpusContext
from polyglotdb.io.enrichment import enrich_speakers_from_csv, enrich_lexicon_from_csv
from polyglotdb.acoustics.formants.refined import analyze_formant_points_refinement

# =============== FORMANT CONFIGURATION ===============

duration_threshold = 0.05
nIterations = 1


# =====================================================

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
        parser.call_back = call_back
        beg = time.time()
        c.load(parser, corpus_dir)
        end = time.time()
        print('Loading took: {}'.format(end - beg))


def basic_enrichment(config, syllabics):
    with CorpusContext(config) as g:
        if not 'utterance' in g.annotation_types:
            print('encoding utterances')
            begin = time.time()
            g.encode_pauses('^<SIL>$')
            # g.encode_pauses('^[<{].*$', call_back = call_back)
            g.encode_utterances(min_pause_length=0.15)  # , call_back = call_back)
            # g.encode_utterances(min_pause_length = 0.5, call_back = call_back)
            print('Utterance enrichment took: {}'.format(time.time() - begin))

        if syllabics and 'syllable' not in g.annotation_types:
            print('encoding syllables')
            begin = time.time()
            g.encode_syllabic_segments(syllabics)
            g.encode_syllables('maxonset')
            print('Syllable enrichment took: {}'.format(time.time() - begin))

        print('enriching utterances')
        if syllabics and not g.hierarchy.has_token_property('utterance', 'speech_rate'):
            begin = time.time()
            g.encode_rate('utterance', 'syllable', 'speech_rate')
            print('Speech rate encoding took: {}'.format(time.time() - begin))

        if not g.hierarchy.has_token_property('utterance', 'num_words'):
            begin = time.time()
            g.encode_count('utterance', 'word', 'num_words')
            print('Word count encoding took: {}'.format(time.time() - begin))

        if syllabics and not g.hierarchy.has_token_property('utterance', 'num_syllables'):
            begin = time.time()
            g.encode_count('utterance', 'syllable', 'num_syllables')
            print('Syllable count encoding took: {}'.format(time.time() - begin))

        if syllabics and not g.hierarchy.has_token_property('syllable', 'position_in_word'):
            print('enriching syllables')
            begin = time.time()
            g.encode_position('word', 'syllable', 'position_in_word')
            print('Syllable position encoding took: {}'.format(time.time() - begin))

        if syllabics and not g.hierarchy.has_token_property('syllable', 'num_phones'):
            begin = time.time()
            g.encode_count('syllable', 'phone', 'num_phones')
            print('Phone count encoding took: {}'.format(time.time() - begin))

        # print('enriching words')
        # if not g.hierarchy.has_token_property('word', 'position_in_utterance'):
        #    begin = time.time()
        #    g.encode_position('utterance', 'word', 'position_in_utterance')
        #    print('Utterance position encoding took: {}'.format(time.time() - begin))

        if syllabics and not g.hierarchy.has_token_property('word', 'num_syllables'):
            begin = time.time()
            g.encode_count('word', 'syllable', 'num_syllables')
            print('Syllable count encoding took: {}'.format(time.time() - begin))

        if syllabics and re.search(r"\d", syllabics[0]):  # If stress is included in the vowels
            g.encode_stress_to_syllables("[0-9]", clean_phone_label=False)
            print("encoded stress")


def lexicon_enrichment(config, lexicon_files, dialect_code):
    with CorpusContext(config) as g:

        for lf in lexicon_files:
            if not os.path.exists(lf):
                print('Could not find {}'.format(lf))
                continue
            if dialect_code not in lf and g.hierarchy.has_type_property('word', 'UnisynPrimStressedVowel1'.lower()):
                print('Dialect independent enrichment already loaded, skipping.')
                continue
            if dialect_code in lf and g.hierarchy.has_type_property('word', 'UnisynPrimStressedVowel2_{}'.format(
                    dialect_code).lower()):
                print('Dialect specific enrichment already loaded, skipping.')
                continue
            begin = time.time()
            enrich_lexicon_from_csv(g, lf)
            print('Lexicon enrichment took: {}'.format(time.time() - begin))


def speaker_enrichment(config, speaker_file):
    if not os.path.exists(speaker_file):
        print('Could not find {}, skipping speaker enrichment.'.format(speaker_file))
        return
    with CorpusContext(config) as g:
        if not g.hierarchy.has_speaker_property('gender'):
            begin = time.time()
            enrich_speakers_from_csv(g, speaker_file)
            print('Speaker enrichment took: {}'.format(time.time() - begin))
        else:
            print('Speaker enrichment already done, skipping.')


def sibilant_acoustic_analysis(config, sibilant_segments, script_path):
    # Encode sibilant class and analyze sibilants using the praat script
    with CorpusContext(config) as c:
        if c.hierarchy.has_token_property('phone', 'cog'):
            print('Sibilant acoustics already analyzed, skipping.')
            return
        print('Beginning sibilant analysis')
        c.encode_class(sibilant_segments, 'sibilant')
        print('sibilants encoded')

        # analyze all sibilants using the script found at script_path
        beg = time.time()
        c.analyze_script('sibilant', script_path)
        end = time.time()
        print('Sibilant analysis took: {}'.format(end - beg))


def formant_acoustic_analysis(config, stressed_vowels):
    with CorpusContext(config) as c:
        if c.hierarchy.has_token_property('phone', 'F1'):
            print('Formant acoustics already analyzed, skipping.')
            return
        print('Beginning formant analysis')
        beg = time.time()
        metadata = analyze_formant_points_refinement(c, stressed_vowels, duration_threshold=duration_threshold,
                                                     num_iterations=nIterations)
        end = time.time()
        print('Analyzing formants took: {}'.format(end - beg))


def formant_export(config, stressed_vowels, csv_path, dialect_code):  # Gets information into a csv

    # Unisyn columns
    other_vowel_codes = ['unisynPrimStressedVowel2_{}'.format(dialect_code),
                         'UnisynPrimStressedVowel3_{}'.format(dialect_code),
                         'UnisynPrimStressedVowel3_XSAMPA',
                         'AnyRuleApplied_{}'.format(dialect_code)]

    with CorpusContext(config) as c:
        print('Beginning formant export')
        beg = time.time()
        q = c.query_graph(c.phone).filter(c.phone.label.in_(stressed_vowels))

        q = q.columns(c.phone.speaker.name.column_name('speaker'), c.phone.discourse.name.column_name('discourse'),
                      c.phone.id.column_name('phone_id'), c.phone.label.column_name('phone_label'),
                      c.phone.begin.column_name('begin'), c.phone.end.column_name('end'),
                      c.phone.duration.column_name('duration'),
                      c.phone.following.label.column_name('following_phone'),
                      c.phone.previous.label.column_name('previous_phone'), c.phone.word.label.column_name('word'),
                      c.phone.F1.column_name('F1'), c.phone.F2.column_name('F2'), c.phone.F3.column_name('F3'),
                      c.phone.B1.column_name('B1'), c.phone.B2.column_name('B2'), c.phone.B3.column_name('B3'))
        if c.hierarchy.has_type_property('word', 'UnisynPrimStressedVowel1'.lower()):
            q = q.columns(c.phone.word.unisynprimstressedvowel1.column_name('UnisynPrimStressedVowel1'))
        for v in other_vowel_codes:
            if c.hierarchy.has_type_property('word', v.lower()):
                q = q.columns(getattr(c.phone.word, v.lower()).column_name(v))
        q.to_csv(csv_path)
        end = time.time()
        print('Query took: {}'.format(end - beg))
        print("Results for query written to " + csv_path)


def sibilant_export(config, csv_path, dialect_code):
    with CorpusContext(config) as c:
        # export to CSV all the measures taken by the script, along with a variety of data about each phone
        print("Beginning sibilant export")
        beg = time.time()
        qr = c.query_graph(c.phone).filter(c.phone.subset == 'sibilant')
        qr = qr.filter(c.phone.begin == c.phone.syllable.word.begin)
        # qr = c.query_graph(c.phone).filter(c.phone.subset == 'sibilant')
        # this exports data for all sibilants
        qr = qr.columns(c.phone.speaker.name.column_name('speaker'),
                        c.phone.discourse.name.column_name('discourse'),
                        c.phone.id.column_name('phone_id'), c.phone.label.column_name('phone_label'),
                        c.phone.begin.column_name('begin'), c.phone.end.column_name('end'),
                        c.phone.duration.column_name('duration'),
                        c.phone.following.label.column_name('following_phone'),
                        c.phone.previous.label.column_name('previous_phone'),
                        c.phone.syllable.word.label.column_name('word'),
                        c.phone.syllable.phone.filter_by_subset('onset').label.column_name('onset'),
                        c.phone.syllable.phone.filter_by_subset('nucleus').label.column_name('nucleus'),
                        c.phone.cog.column_name('cog'), c.phone.peak.column_name('peak'),
                        c.phone.slope.column_name('slope'), c.phone.spread.column_name('spread'))
        qr.to_csv(csv_path)
        end = time.time()
        print('Query took: {}'.format(end - beg))
        print("Results for query written to " + csv_path)


def basic_queries(config):
    from polyglotdb.query.base.func import Sum
    with CorpusContext(config) as c:
        print('beginning basic queries')
        q = c.query_lexicon(c.lexicon_phone).columns(c.lexicon_phone.label.column_name('label'))
        results = q.all()
        print('The phone inventory is:', ', '.join(sorted(x['label'] for x in results)))

        q = c.query_speakers().columns(c.speaker.name.column_name('name'))
        results = q.all()
        print('The speakers in the corpus are:', ', '.join(sorted(x['name'] for x in results)))

        q = c.query_graph(c.utterance).columns(Sum(c.utterance.duration).column_name('result'))
        results = q.all()
        print('The total length of speech in the corpus is: {} seconds'.format(results[0]['result']))
