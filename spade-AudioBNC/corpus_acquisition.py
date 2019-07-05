import os
import urllib.request

audiobnc_directory = '/media/share/corpora/AudioBNC'

wav_file_path = os.path.join(audiobnc_directory, 'filelist-wav.txt')
wav_dir = os.path.join(audiobnc_directory, 'wavs')
tg_dir = os.path.join(audiobnc_directory, 'textgrids')
tg_file_path = os.path.join(audiobnc_directory, 'filelist-textgrid.txt')

with open(wav_file_path, 'r') as f:
    for line in f:
        line = line.strip()
        name = line.split('/')[-1]
        out_file = os.path.join(wav_dir, name)
        urllib.request.urlretrieve(line, out_file)

with open(tg_file_path, 'r') as f:
    for line in f:
        line = line.strip()
        name = line.split('/')[-1]
        out_file = os.path.join(tg_dir, name)
        urllib.request.urlretrieve(line, out_file)
