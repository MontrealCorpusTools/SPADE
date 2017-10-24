import os
import sys
import csv
import xlrd
from datetime import date
import re
import subprocess
from statistics import mean
from textgrid import TextGrid, IntervalTier

orig_dir = r'/media/share/corpora/ICE-Can'
output_dir = r'/media/share/corpora/ICE-Can/to_align'

os.makedirs(output_dir, exist_ok=True)

file_code_to_speaker = {}
speaker_data = {}


def reorganize_meta_file():
    meta_file = os.path.join(orig_dir, 'VOICE_meta_2015_May.xls')
    excel = xlrd.open_workbook(meta_file)  # Load in metadata
    sheet = excel.sheet_by_index(1)
    print(sheet)
    print(sheet.nrows)
    cur_file = None
    for r in range(1, sheet.nrows):
        data = {}
        file_name = sheet.cell_value(r, 0)
        if file_name:
            cur_file = file_name

        speaker_code = sheet.cell_value(r, 4)
        if not speaker_code:
            continue
        record_date = sheet.cell_value(r, 6)
        age = sheet.cell_value(r, 14)
        if isinstance(record_date, str):
            record_year = int(record_date[-4:])
        elif isinstance(record_date, float):
            record_year = date.fromtimestamp(record_date).year
        age_uncertain = True
        birth_year = None
        if age:
            if isinstance(age, float):
                age_uncertain = False
                birth_year = record_year - age
            elif isinstance(age, str):
                ages = re.findall(r'(\d+)', age)
                if len(ages) == 1:
                    birth_year = record_year - int(ages[0])
                else:
                    birth_year = record_year - int(mean(map(int, ages)))
        data['birthyear'] = birth_year
        data['age_uncertain'] = age_uncertain

        first_name = sheet.cell_value(r, 11)
        last_name = sheet.cell_value(r, 12)
        if first_name and last_name:
            name = first_name + ' ' + last_name
        elif first_name:
            name = first_name
        elif last_name:
            name = last_name
        else:
            name = 'unknown'

        data['sex'] = sheet.cell_value(r, 13)
        data['birthplace'] = sheet.cell_value(r, 15)
        data['nationality'] = sheet.cell_value(r, 16)
        data['L1'] = sheet.cell_value(r, 17)
        data['L2'] = sheet.cell_value(r, 18)
        speaker_data[name] = data
        file_code_to_speaker[(cur_file, speaker_code)] = name
    print(file_code_to_speaker)
    print(speaker_data)
    with open(os.path.join(output_dir, 'speaker_data.csv'), 'w', encoding='utf8') as f:
        writer = csv.DictWriter(f,
                                ['name', 'sex', 'birthyear', 'age_uncertain', 'birthplace', 'nationality', 'L1', 'L2'])
        writer.writeheader()
        for s, v in speaker_data.items():
            v.update({'name': s})
            writer.writerow(v)


def parse_time(timestamp):
    timestamp = timestamp.strip()
    if timestamp.endswith('>'):
        timestamp = timestamp[:-1]
    if not timestamp:
        return None
    timestamp = timestamp.replace('l', ':')
    if len(timestamp) in [8, 9, 10] and '.' not in timestamp and ':' in timestamp:
        if timestamp[1] == ':':
            ind = 4
        elif timestamp[2] == ':':
            ind = 5
        timestamp = timestamp[:ind] + '.' + timestamp[ind:]
    if all(x not in timestamp for x in ':;.>'):
        timestamp = timestamp[0] + ':' + timestamp[1:3] + '.' + timestamp[3:]
    if timestamp == '5:53.1838':
        timestamp = '5:35.1838'
    if timestamp == '2:49.9333':
        timestamp = '2:44.9333'
    if timestamp == '3:26.9667':
        timestamp = '3:36.9667'
    if timestamp == '3:43.4314':
        timestamp = '2:43.4314'
    if timestamp == '046.9988':
        timestamp = '0:46.9988'
    if timestamp == '7:18.7442':
        timestamp = '7:09.7442'
    if timestamp == '0:14.6566':
        timestamp = '0:56.2047'
    if timestamp == '5:33.1267':
        timestamp = '5:32.8570'
    if timestamp == '5:45.4070':
        timestamp = '5:33.010'
    if timestamp == '7:15.1466':
        timestamp = '5:15.1466'
    if timestamp == '7:15.9731':
        timestamp = '5:15.9731'
    if timestamp == '6:44.3467':
        timestamp = '6:33.1124'
    if timestamp == '15:03.4709':
        timestamp = '12:03.4709'
    if timestamp == '15:03.7071':
        timestamp = '12:03.7071'
    if timestamp == '1:8.6444':
        timestamp = '1:28.6444'
    if timestamp == '12:14.3203':
        timestamp = '12:24.3203'
    if timestamp == '4:40.1876':
        timestamp = '3:40.1876'
    if timestamp == '2:35.0000':
        timestamp = '2:45.0000'
    if timestamp == '6:03.9332':
        timestamp = '7:03.9332'
    if timestamp == '0:04.2748':
        timestamp = '0:18.1925'

    m = re.match(r'(\d{1,2})[:;.>]{0,2}(\d+)[.:]{1,2}(\d+)>?', timestamp)
    if m is None:
        print(timestamp)
        error
    minutes, seconds, ms = m.groups()
    minutes, seconds, ms = int(minutes), int(seconds), int(ms) / (10 ** (len(ms)))
    seconds = int(seconds) + int(minutes) * 60 + ms
    # print(timestamp)
    return seconds


def parse_text(text):
    # print(text)
    text = text.replace("</-> <=> </w>", "</w> </-> <=>")
    text = text.replace('<is /->', 'is')
    text = re.sub(r"&(a|A)circumflex;", "â", text)
    text = re.sub(r"&(e|E)circumflex;", "ê", text)
    text = re.sub(r"&(i|I)circumflex;", "î", text)
    text = re.sub(r"&(o|O)circumflex;", "ô", text)
    text = re.sub(r"&(u|U)circumflex;", "û", text)
    text = re.sub(r"&[aA]uml;", "ä", text)

    text = re.sub(r"&(e|E)acute;", "é", text)

    text = re.sub(r"&(a|A)grave;", "à", text)
    text = re.sub(r"&(e|E)grave;", "è", text)

    text = re.sub(r"&(i|I)uml;", "ï", text)
    text = re.sub(r"&(e|E)uml;", "ë", text)
    text = re.sub(r"&(o|O)uml;", "ö", text)

    text = re.sub(r"&(c|C)cedille;", "ç", text)
    text = re.sub(r"&(c|C)cedilla;", "ç", text)
    text = re.sub(r"<w>\s+([a-zA-Z' ]+)\s+('\w*)\s+</w>", r"\1\2", text)  # Clitics
    text = re.sub(r"<w>\s+([a-zA-Z' ]+)\s+'\s+(\w*)\s*</w>", r"\1'\2", text)  # Clitics

    text = re.sub(r"(<,>|<,,>)", "", text)  # Pauses
    # print(text)

    text = re.sub(
        "<}> <->([\w ]+)<}> <-> <\.> ([-\w']+) </\.> </-> <\+> [-\w']+ </\+> </}> </-> <=> ([-\w' ]+) </=> </}>",
        r'\1[\2-] \3', text)

    if '<&>' in text:
        if '</&>' in text:
            text = re.sub(r"<&>.*</&>", r"", text)  # Notes
        else:
            text = re.sub(r"<&>.*", r"", text)  # Notes
    text = re.sub(r"<@>.*</@>?", "<beep_sound>", text)  # Excised words
    text = re.sub(r"< ?O>.*</O>", "", text)  # Comments
    text = re.sub(r"<unclear>.*</unclear>", r"<unk> ", text)  # Unclear
    text = re.sub(r"<\?> ([-a-zA-Z'_ ]+) </?\?>", r"\1", text)  # Uncertain transcription
    text = re.sub(r"<quote> | </quote>", "", text)
    text = re.sub(r"<mention> | </mention>", "", text)
    text = re.sub(r"<foreign> | </foreign>", "", text)
    text = re.sub(r"<indig> | </indig>", "", text)
    text = re.sub(r"(</?[-}{=+[w?#]?[12]?>|</})", "", text)
    text = re.sub(r"<\s?[.]>\s+(\w+)-?\s?</\s?[.]>", r"[\1-]", text)  # Cutoffs
    text = re.sub(r"<\s?[.]>\s+([\w ]+)\s?</\s?[.]>", r"\1", text)  # Cutoffs
    text = re.sub(r"(</I>)", "", text)  # End of transcript

    text = re.sub(r"<}> <-> .* </-> <\+> (.*) </\+> </}>", r"\1", text)  # Variants
    # print(text)
    text = re.sub(r"<}>\s+<->\s+([-a-zA-Z'_ \][<>]*)\s+</->\s+([-\w[\] ]+)?\s*<=>\s+([-a-zA-Z'_ ]*)\s+</=> </}>",
                  r"\1 \2 \3", text)  # Restarts
    text = re.sub(r"(<X>.*</X>)", r"", text)  # Excluded

    text = text.strip()
    text = text.split()
    new_text = []
    for i, t in enumerate(text):
        if i != len(text) - 1:
            if t.lower() == "'er" and text[i + 1].lower() == 'her':
                continue
            if t.lower() == "'em" and text[i + 1].lower() == 'them':
                continue
            if t.lower() == "'im" and text[i + 1].lower() == 'him':
                continue
            if t.lower() == "lemme" and text[i + 1].lower() == 'let':
                continue
            if t.endswith("'") and t[:-1] == text[i + 1].lower()[:-1]:
                continue
        new_text.append(t)
    return ' '.join(new_text)


def parse_transcript(path):
    file_name = os.path.splitext(os.path.basename(path))[0]
    tg_path = path.replace(os.path.join(orig_dir, 'txt'), output_dir).replace('.txt', '.TextGrid')
    tg = TextGrid()
    tiers = {}
    continuation = False
    prev_speaker = None
    with open(path, 'r', encoding='utf8') as f:
        for i, line in enumerate(f):
            line = line.strip()
            if i == 0:
                continue
            if not line:
                continue
            if line in ['<I>', '</I>']:
                continue
            if '<O>' in line:
                continue
            if line.startswith('&'):
                continue
            m = re.match(r'^<\$(\w)>.*<start=?([0-9:.;l ]+) end6?=([0-9>:.;l ]*)>?[?]?\s+<#>(.+)$', line)
            if m is None:
                text = parse_text(line)
                try:
                    tiers[speaker][-1].mark += ' ' + text
                except UnboundLocalError:
                    continue
                    # error
            else:
                speaker_code, start, end, text = m.groups()
                if speaker_code == 'Z':
                    continue
                try:
                    speaker = file_code_to_speaker[(file_name, speaker_code)]
                except KeyError:
                    speaker = 'unknown_{}_{}'.format(file_name, speaker_code)
                if speaker not in tiers:
                    tiers[speaker] = IntervalTier(speaker)
                start = parse_time(start)
                end = parse_time(end)
                text = parse_text(text)
                if text == "Again he's quoting":
                    continue
                if not text:
                    continue
                if start is None:
                    if prev_speaker != speaker:
                        continue
                    continuation = True
                    tiers[speaker][-1].mark += ' ' + text
                if '<' in text.replace('<beep_sound>', '').replace('<unk>', ''):
                    print(file_name, start, end, text)
                    print(line)
                if continuation or (len(tiers[speaker]) > 0 and start - tiers[speaker][-1].maxTime < 0.1):
                    tiers[speaker][-1].mark += ' ' + text
                    if not continuation:
                        tiers[speaker][-1].maxTime = end
                    continuation = False
                else:
                    tiers[speaker].add(start, end, text)

                # print(speaker)
                # print(start, end)
                # print(text)
                prev_speaker = speaker
    print(tiers.keys(), [len(x) for x in tiers.values()])
    for v in tiers.values():
        tg.append(v)
    tg.write(tg_path)


def parse_transcripts():
    trans_dir = os.path.join(orig_dir, 'txt')
    files = sorted(os.listdir(trans_dir))
    for f in files:
        if f == '.DS_Store':
            continue
        # if f != 'S2B-026_1.txt':
        #    continue
        if f in ['S2B-018_3.txt']:  # Lacking information
            continue
        print(f)
        parse_transcript(os.path.join(trans_dir, f))


def convert_wavs():
    wav_dir = os.path.join(orig_dir, 'wav')
    for f in os.listdir(wav_dir):
        if not f.endswith('.wav'):
            continue
        input_wav = os.path.join(wav_dir, f)
        output_wav = input_wav.replace(wav_dir, output_dir)
        if not os.path.exists(output_wav):
            com = ['sox', input_wav, '-t', 'wavpcm', '-b', '16', '-e', 'signed-integer', output_wav, 'remix', '1',
                   'rate', '-I', str(22500)]

            subprocess.call(com)


if __name__ == '__main__':
    reorganize_meta_file()
    convert_wavs()
    parse_transcripts()
