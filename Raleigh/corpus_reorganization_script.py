import os
import csv
import random
import shutil
from textgrid import TextGrid, IntervalTier
import subprocess

base_dir = os.path.dirname(os.path.abspath(__file__))

speaker_path = os.path.join(base_dir, 'raleigh_files_sub.csv')
small_raleigh_dir = os.path.join(os.path.dirname(base_dir), 'Raleigh')
original_tg_dir = os.path.join(base_dir, 'long_textgrids')
# shutil.rmtree(small_raleigh_dir, ignore_errors=True)
wav_dir = os.path.join(base_dir, 'textgrid-wav')
os.makedirs(small_raleigh_dir, exist_ok=True)
selected_speaker_path = os.path.join(small_raleigh_dir, 'speaker_data.csv')

speaker_data = {}

selected_speakers = []
selected_counts = {('old', 'male'): 0, ('old', 'female'): 0, ('young', 'male'): 0, ('young', 'female'): 0}

num_speakers = 20

median_age = 1957

with open(speaker_path, 'r') as f:
    reader = csv.DictReader(f)
    for line in reader:
        speaker_data[line['speaker']] = {'birthyear': int(line['birthyear']), 'sex': line['sex']}

speakers = list(speaker_data.keys())
random.shuffle(speakers)
for s in speakers:
    age = 'old'
    if speaker_data[s]['birthyear'] > 1957:
        age = 'young'
    sex = speaker_data[s]['sex']
    # if selected_counts[(age, sex)] > num_speakers/4 - 1:
    #    continue
    selected_counts[(age, sex)] += 1
    selected_speakers.append(s)

print(sorted(selected_speakers))

with open(selected_speaker_path, 'w') as f:
    writer = csv.writer(f)
    writer.writerow(['speaker', 'birthyear', 'sex'])
    for s in selected_speakers:
        print(s)
        writer.writerow([s, speaker_data[s]['birthyear'], speaker_data[s]['sex']])
        for f in os.listdir(original_tg_dir):
            if not f.startswith(s):
                continue
            print(f)
            wav_f = f.replace('.TextGrid', '.wav')
            wav_path = os.path.join(wav_dir, wav_f)
            if not os.path.exists(wav_path):
                continue
            textgrid_path = os.path.join(original_tg_dir, f)
            tg = TextGrid()
            try:
                tg.read(textgrid_path)  # Read into a textgrid
            except:
                print(f + " cannot be read into a textgrid.")
                continue
            new_tg = TextGrid()
            for tier in tg.tiers:
                if tier.name in ['Sphone']:
                    tier.name = s + ' - ' + 'phone'
                elif tier.name == 'S1phone':
                    tier.name = s + '1 - phone'
                elif tier.name in ['Sword']:
                    tier.name = s + ' - ' + 'word'
                elif tier.name == 'S1word':
                    tier.name = s + '1 - word'
                elif tier.name == 'Iphone':
                    tier.name = 'Interviewer' + s + ' - ' + 'phone'
                elif tier.name == 'Iword':
                    tier.name = 'Interviewer' + s + ' - ' + 'word'
                else:
                    continue
                new_tg.tiers.append(tier)
            if not new_tg.tiers:
                continue
            os.makedirs(os.path.join(small_raleigh_dir, s), exist_ok=True)
            new_tg.write(os.path.join(small_raleigh_dir, s, f))
            new_wav_path = os.path.join(small_raleigh_dir, s, wav_f)
            if not os.path.exists(new_wav_path):
                subprocess.call(['sox', wav_path, new_wav_path, 'rate', '-I', str(22500)])
