import os
import re
import csv
data_dir =r'H:\Data\sotc_all'

speaker_data = []

for d in os.listdir(data_dir):
    section_dir = os.path.join(data_dir, d)
    for speaker in os.listdir(section_dir):
        m = re.match('(\d+)(-mc)?-([MOY])-([mf])(\d+)', speaker)

        print(m.groups())
        decade, middle_class, age, sex, code = m.groups()
        if middle_class is not None:
            socio_class = 'middle_class'
        else:
            socio_class = 'working_class'
        if age == 'Y':
            age = 'younger'
        elif age == 'O':
            age = 'older'
        elif age == 'M':
            age = 'middle-aged'
        if sex == 'f':
            sex = 'female'
        else:
            sex = 'male'
        speaker_data.append({'name':speaker, 'recording_decade':decade, 'socio_class': socio_class, 'age':age, 'sex':sex})

path = os.path.join(data_dir, 'speaker_data.csv')
with open(path, 'w', encoding='utf8', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=speaker_data[0].keys())
    writer.writeheader()
    for line in speaker_data:
        writer.writerow(line)
print(speaker_data)