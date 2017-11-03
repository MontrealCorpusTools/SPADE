import os
import sys
import csv
sys.setrecursionlimit(100000000)
import wave
import xml.etree.ElementTree as ET
from textgrid import TextGrid, IntervalTier
from bs4 import BeautifulSoup
from alignment.sequence import Sequence
from alignment.vocabulary import Vocabulary
from alignment.sequencealigner import SimpleScoring, GlobalSequenceAligner, StrictGlobalSequenceAligner

base_dir = '/media/share/corpora/AudioBNC'

textgrid_dir = os.path.join(base_dir, 'textgrids')

textgrids = os.listdir(textgrid_dir)

wav_dir = os.path.join(base_dir, 'wavs')
wavs = os.listdir(wav_dir)

bnc_xml_dir = r'/media/share/corpora/BNC/Texts'

speaker_header = ['id', 'sex', 'agegroup', 'dialect_group', 'age', 'dialect']

def load_bnc_code(code):
    path = os.path.join(bnc_xml_dir, code[0], code[:2], code + '.xml')
    with open(path, 'r', encoding='utf8') as f:
        soup = BeautifulSoup(f, 'html.parser')
    recording_data = {x['n']: {h: x[h] for h in ['date', 'dur', 'time', 'type', 'xml:id'] if h in x} for x in
                      soup.find_all('recording')}
    # print(recording_data)
    # print(soup)
    partcipant_description = soup.find('particdesc')
    n_participants = partcipant_description['n']
    people = partcipant_description.find_all('person')
    speakers = {}
    for p in people:
        # print(p)
        d = {}
        d['sex'] = p['sex']
        d['agegroup'] = p['agegroup']
        d['dialect_group'] = p['dialect']
        try:
            d['name'] = p.find('persname').get_text()
        except AttributeError:
            d['name'] = None
        try:
            d['age'] = p.find('age').get_text()
        except AttributeError:
            d['age'] = None
        try:
            d['dialect'] = p.find('dialect').get_text()
        except AttributeError:
            d['dialect'] = None
        speakers[p['xml:id']] = d
    # print(partcipant_description)
    # print(speakers)
    # print(soup)
    transcripts = {}
    for r in recording_data.keys():
        d = soup.find('div', n=r)
        if d is not None:
            utts = d.find_all('u')
        else:
            utts = soup.find_all('u')
        data = []
        for u in utts:
            words = u.find_all('w')
            new_words = []
            for w in words:
                if w['c5'] == 'PUN':
                    continue
                w = w.get_text().upper().strip()
                if new_words and (w.startswith("'") or w == "N'T"):
                    new_words[-1] = (new_words[-1][0] +w, u['who'])
                else:
                    new_words.append((w, u['who']))
            data.extend(new_words)
        transcripts[r] = data
    # for k, v in transcripts.items():
    #    print(k)
    #    print(v)

    return speakers, recording_data, transcripts


def calc_duration(path):
    with wave.open(path, 'rb') as f:
        frames = f.getnframes()
        rate = f.getframerate()
        duration = frames / float(rate)
    return duration


for f in wavs:
    if not f.endswith('.wav'):
        continue
    path = os.path.join(wav_dir, f)
    duration = calc_duration(path)
    name, _ = os.path.splitext(f)
    relevant_tgs = [os.path.join(textgrid_dir, x) for x in textgrids if x.startswith(name)]
    bnc_cache = {}
    speaker_word_tiers = {}
    speaker_phone_tiers = {}
    out_path = path.replace('.wav', '.TextGrid')
    if os.path.exists(out_path):
        continue
    speakers = {}
    for tg_path in relevant_tgs:
        print(tg_path)
        r_code, bnc_code = tg_path.split('_')[-3:-1]
        if bnc_code == 'KDP' and r_code == '000419':
            continue
        if bnc_code not in bnc_cache:
            bnc_cache[bnc_code] = load_bnc_code(bnc_code)
            speakers.update(bnc_cache[bnc_code][0])
        _, recording_data, transcripts = bnc_cache[bnc_code]
        transcript = transcripts[r_code]
        tg = TextGrid()
        tg.read(tg_path)
        word_tier = tg.getFirst('word')
        #print([x.mark for x in word_tier])
        phone_tier = tg.getFirst('phone')
        trans_ind = 0
        prev_oov = False
        a = Sequence([x[0] for x in transcript])
        b = Sequence([x.mark for x in word_tier])

        # Create a vocabulary and encode the sequences.
        v = Vocabulary()
        aEncoded = v.encodeSequence(a)
        bEncoded = v.encodeSequence(b)

        # Create a scoring and align the sequences using global aligner.
        scoring = SimpleScoring(2, -1)
        aligner = GlobalSequenceAligner(scoring, -2)
        score, encodeds = aligner.align(aEncoded, bEncoded, backtrace=True)

        # Iterate over optimal alignments and print them.
        for encoded in encodeds:
            alignment = v.decodeSequenceAlignment(encoded)
            #print(alignment)
            #print('Alignment score:', alignment.score)

            #print('Percent identity:', alignment.percentIdentity())
            trans_ind = 0
            inds = ['-']
            for x in alignment:
                if x[0] != '-':
                    inds.append(trans_ind)
                    trans_ind += 1
                else:
                    inds.append('-')
            inds.append('-')
        #print(inds)
        #print([x for x in range(len(inds))])
        #print(len(word_tier))
        word_speakers = []
        cur_speaker = None
        cur_turn = [0, None]
        for j, i in enumerate(inds):
            if i == '-':
                continue
            s = transcript[i][1]
            if cur_speaker != s:
                if cur_turn[1] is not None:
                    word_speakers.append((cur_speaker, cur_turn))
                    cur_turn = [None, None]
                cur_speaker = s
            if cur_turn[0] is None:
                cur_turn[0] = j
            cur_turn[1] = j + 1
        if cur_turn[0] is not None:
            word_speakers.append((cur_speaker, cur_turn))
        #print(word_speakers)
        for i, w in enumerate(word_tier):
            for s, r in word_speakers:
                if r[0] == r[1] and i == r[0]:
                    speaker = s
                    break
                elif i >= r[0] and i < r[1]:
                    speaker = s
                    break
            else:
                speaker = word_speakers[-1][0]
            if speaker not in speaker_word_tiers:
                speaker_word_tiers[speaker] = []
                speaker_phone_tiers[speaker] = []
            speaker_word_tiers[speaker].append(w)
            from decimal import Decimal
            if w.minTime == Decimal('1385.9725'):
                print('found', w, tg_path)
            for p in phone_tier:
                mid_point = p.minTime + (p.maxTime - p.minTime) / 2
                if mid_point > w.minTime and mid_point < w.maxTime:
                    speaker_phone_tiers[speaker].append(p)
    new_tg = TextGrid()
    if not speaker_word_tiers:
        print('could not find tiers for {}'.format(out_path))
    for s in sorted(speaker_word_tiers.keys()):
        w_tier = IntervalTier('{} - word'.format(s), 0, duration)
        p_tier = IntervalTier('{} - phone'.format(s), 0, duration)
        for w in sorted(speaker_word_tiers[s]):
            if len(w_tier) and w_tier[-1].mark == 'sp' and w_tier[-1].maxTime > w.minTime:
                w_tier[-1].maxTime = w.minTime
            #print(w)
            w_tier.addInterval(w)
        for p in sorted(speaker_phone_tiers[s]):
            #print(p)
            try:
                p_tier.addInterval(p)
            except ValueError:
                pass
        new_tg.append(w_tier)
        new_tg.append(p_tier)

    new_tg.write(out_path)

    # print(tg)

