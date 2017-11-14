import os
import sys
import csv
import re
import wave
import subprocess
import socket
from textgrid.textgrid import Interval, IntervalTier, TextGrid

host = socket.gethostname()

if host == 'Tin-Man':
    data_dir = r'E:\Data\SB\SantaBarbara'
    output_dir = r'E:\Data\SB\mm_tg'
else:
    data_dir = r'/media/share/corpora/SantaBarbara'
    output_dir = r'/media/share/corpora/SantaBarbara_for_MFA'
os.makedirs(output_dir, exist_ok=True)


def clean_trans(trans):
    # Annotations inside ((X)) are comments, ignored
    if trans.startswith('(('):
        return [], False
    # Numbers and brackets align overlapping parts
    trans = re.sub(r'[0-9]', '', trans).replace('[', '').replace(']', '')

    # Punctuation is unnecessary, even when used to mark something linguistically (something pitch perception related)
    trans = re.sub(r'[.,!?]', '', trans)

    # Laughter length is marked by number of @'s, not necessary
    trans = re.sub(r'\s@+\s@+(\s@+\s)*', ' @ ', trans)

    trans = trans.split()
    new_trans = []
    if not trans:
        return [], False
    # (H) annotates breath (= is long)
    breaths = ['(H)', '(H)=', '(Hx)', 'T_(Hx)', 'a(hx)', '@(H)=', '@(H)', '@(Hx)', '(@Hx)', '(hx).', '(Hx', '(Hx=']
    breath_start = trans[0] in breaths
    for t in trans:

        skip = False
        # Punctuation that is used to mark continuations or small pauses in utterances, unnecessary

        for skip_mark in ['...', '--', '__', '..', 'XX', '(TSK)', '(SWALLOW)', '&', '+'] + breaths:
            if t.lower().startswith(skip_mark.lower()):
                skip = True
        for skip_mark in breaths:
            if t.lower().endswith(skip_mark.lower()):
                skip = True

        # Bracketing is not useful for alignment, usually voice quality notes (laughter, etc)
        if t.endswith('>') or t.startswith('<') or t in ['-', 'X']:
            skip = True

        # % marks a break of some kind, not necessary for the aligner
        if '%' in t:
            skip = True
        if skip:
            continue

        # Words ending in a dash (or for some annotators an underscore) are cutoffs,
        # put them in [] for the aligner to mark as UNK

        # Tilde marks excised names, likewise better to specify as UNK

        if t.endswith('-') or t.endswith('_') or t.startswith('~'):
            t = '[' + t.replace('_', '-') + ']'
        t = re.sub(r'^_', '', t)

        # Words produced while laughing often have laugh markers at the beginning or end, not necessary for alignment
        if t.startswith('@'):
            m = re.search(r'\w', t)
            if m is None:
                t = '[LAUGH]'  # Make laughter more similar to other non speech sounds
            else:
                t = re.sub(r'^@', '', t)
        if t.endswith('@'):
            t = re.sub(r'@$', '', t)

        # = is a length marker, wholly unnecessary
        t = t.replace('=', '')

        # some annotators use underscore instead of dash for compound words, standardizes them to dash
        t = t.replace('_', '-')
        t = t.replace('#', '')
        t = t.replace('+', '')
        if t == 'la@ter':
            t = 'later'
        if t == 'apple-@cinnamon':
            t = 'apple-cinnamon'
        t = t.replace('@', ' ').strip()
        if t:
            new_trans.append(t)
    return ' '.join(new_trans), breath_start


def get_duration(wav_path):
    with wave.open(wav_path, 'rb') as f:
        sr = f.getframerate()
        samp_count = f.getnframes()
        return samp_count / sr


def copy_wav_path(wav_path, out_path):
    # Extract only channel one (both channels have identical microphone source)
    if os.path.exists(out_path):
        return
    subprocess.call(['sox', wav_path, out_path, 'remix', '1'])

from collections import defaultdict

def load_segment_table(path):
    speaker_mapping = defaultdict(list)
    with open(path, 'r', encoding='utf8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            line = line.split()
            recording = line[0]
            if len(line) < 3:
                continue
            if line[1] == 'speaker:' and line[2] != 'not':
                speaker_mapping[line[2]].append(recording)
    return speaker_mapping

def load_speaker_table(path):
    speaker_info = {}
    with open(path, 'r', encoding='utf8') as f:
        for line in f:
            line = line.strip()
            if line.startswith('*'):
                continue
            if not line:
                continue
            line = line.split(',')
            id = line[0]
            speaker_info[id] = {
                'name': line[1],
                'gender': line[2],
                'age': line[3],
                'dialect': line[4],
                'dialect_state': line[5],
                'current_state': line[6],
                'highest_education': line[7],
                'years_of_education': line[8],
                'occupation': line[9],
                'ethnicity': line[10],
            }
    return speaker_info



def output_speaker_info(speaker_info):
    with open(os.path.join(data_dir, 'speaker_info.csv'), 'w', encoding='utf8', newline='') as f:
        writer = csv.DictWriter(f, ['name', 'pseudonym', 'gender','age','dialect','dialect_state', 'current_state', 'highest_education', 'years_of_education', 'occupation', 'ethnicity'])
        writer.writeheader()
        for s, info in speaker_info.items():
            info['pseudonym'] = info['name']
            info['name'] = s
            writer.writerow(info)

def find_speaker(speaker, dialog):

    possible = [x for x in speaker_mapping if dialog in speaker_mapping[x]]
    print(possible)
    output_speaker = None
    for s in possible:
        try:
            info = speaker_info[s]
            if info['name'].lower() == speaker.lower():
                output_speaker = s
                break
        except KeyError:
            pass
    if output_speaker is None:
        print(speaker, dialog)
        return speaker
    return output_speaker

parts = ['Part1', 'Part2', 'Part3', 'Part4']

speaker_mapping = defaultdict(list)
speaker_info = {}
for p in parts:
    part_dir = os.path.join(data_dir, p)
    if not os.path.isdir(part_dir):
        continue

    doc_dir = os.path.join(part_dir, 'docs')
    if p == 'Part1':
        doc_dir = doc_dir[:-1]
    segment_tbl = os.path.join(doc_dir, 'segment.tbl')
    speaker_tbl = os.path.join(doc_dir, 'speaker.tbl')
    s_info = load_speaker_table(speaker_tbl)
    s_mapping = load_segment_table(segment_tbl)
    if p == 'Part3':
        new_mapping = {}
        for s, v in s_mapping.items():
            for id, info in s_info.items():
                if s == info['name']:
                    new_mapping[id] = v
                    break
        s_mapping = new_mapping

    for k, v in s_mapping.items():
        speaker_mapping[k].extend(v)
    speaker_info.update(s_info)


for root, directories, files in os.walk(data_dir):
    for trn in sorted(files):
        if not trn.endswith('.trn'):
            continue
        print(trn)
        tg_path = os.path.join(output_dir, trn.replace('.trn', '.TextGrid'))
        wav_path = os.path.join(root, trn.replace('.trn', '.wav'))
        out_wav_path = wav_path.replace(root, output_dir)
        duration = get_duration(wav_path)
        cur_speaker = None
        turns = []
        transcriptions = {}
        cur_turn = []
        speakers = set()
        with open(os.path.join(root, trn), encoding='utf8') as f:
            for line in f:
                line = line.strip()
                line = line.split()
                begin, end = line[0], line[1]
                begin, end = float(begin), float(end)
                if begin == 0 and end == 0:
                    continue
                if end == begin:
                    continue
                if len(line) < 3:
                    continue
                if ':' in line[2]:
                    speaker = line[2].strip().replace(':', '').upper()
                    ind = 3
                else:
                    speaker = ''
                    ind = 2
                if speaker:
                    if speaker != cur_speaker and cur_turn:
                        turns.append(cur_turn)
                        cur_turn = []
                    cur_speaker = speaker
                # There are many weird speaker notes for multiple talkers or environmental noise, not necessary to keep
                if cur_speaker.startswith('>'):
                    continue
                if cur_speaker in ['>ENV', 'MANY', 'X', 'KEN/KEV', 'ALL', '>DOG', '>HORSE', '>RADIO', 'X_3', 'X_2',
                                   'ENV', '>BABY', 'AUD1', 'AUD2', 'AUD3', 'AUD4', 'AUD5', 'AUD6', 'AUD7', 'AUD',
                                   'AUD8', 'AUD_1', 'AUD_2', 'AUD_3', '*X', '>CAT', 'CONGR', '>MAC']:
                    continue
                if cur_speaker.endswith('?'):
                    cur_speaker = cur_speaker[:-1]
                if cur_speaker == '#READ':
                    cur_speaker = 'WALT'
                if cur_speaker.startswith('#'):
                    cur_speaker = cur_speaker[1:]
                speakers.add(cur_speaker)
                trans = ' '.join(line[ind:])
                cur_turn.append((begin, end, cur_speaker, trans))
                if cur_speaker not in transcriptions:
                    transcriptions[cur_speaker] = []
                transcriptions[cur_speaker].append((begin, end, trans))
        print(speakers)
        speakers = [find_speaker(x, trn.replace('.trn', '')) for x in speakers]
        intervals = {x: IntervalTier(x, maxTime=duration) for x in speakers if x}
        for s, turns in transcriptions.items():
            cur_interval = None
            s = find_speaker(s, trn.replace('.trn', ''))
            if s is None:
                continue
            for t in turns:
                if cur_interval is None:
                    mark, breath_start = clean_trans(t[2])
                    if not mark:
                        continue
                    cur_interval = Interval(t[0], t[1], mark)
                else:
                    mark, breath_start = clean_trans(t[2])
                    if not mark:
                        continue
                    if t[0] < cur_interval.maxTime:
                        cur_interval.maxTime = t[0]

                    # Start a new segment when the current annotation starts with a breath (small, reliable pause)
                    # Or when it's been longer than 200ms since the speaker's last annotation
                    if breath_start or t[0] - cur_interval.maxTime > 0.2:
                        begin, end = t[0], t[1]
                        if begin != end:
                            if breath_start:
                                # Adjust the boundaries to be inside of the breath
                                cur_interval.maxTime += 0.14
                                begin += 0.15
                            if begin > end:
                                end = begin + 0.001
                        intervals[s].addInterval(cur_interval)
                        cur_interval = Interval(begin, end, mark)
                    else:
                        cur_interval.mark += ' ' + mark
                        cur_interval.maxTime = t[1]
            if cur_interval is None:
                continue
            if cur_interval.maxTime > duration:
                cur_interval.maxTime = duration
            intervals[s].addInterval(cur_interval)
        print(list(intervals.keys()))
        print([len(x) for x in intervals.values()])
        tg = TextGrid(maxTime=duration)
        for k, v in intervals.items():
            tg.append(v)
        tg.write(tg_path)

        if not os.path.exists(wav_path):
            copy_wav_path(wav_path, out_wav_path)

output_speaker_info(speaker_info)