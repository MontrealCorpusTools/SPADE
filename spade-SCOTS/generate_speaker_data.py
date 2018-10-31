import os
import sys
import csv
import xlrd

orig_dir = r'E:\Data\temp\SCOTS'


def reorganize_meta_file():
    meta_file = os.path.join(orig_dir, 'SCOTS.xlsm')
    new_meta = os.path.join(orig_dir, 'speaker_data.csv')
    excel = xlrd.open_workbook(meta_file)  # Load in metadata
    sheet = excel.sheet_by_index(0)
    print(sheet)
    print(sheet.nrows)
    cur_file = None
    speakers = []
    for r in range(1, sheet.nrows):
        file_name = sheet.cell_value(r, 0)
        start = 4
        try:
            int(file_name)
        except ValueError:
            continue
        print(file_name)
        for si in range(6):
            speaker_start = start + (si * 5) + 0
            id =  sheet.cell_value(r, speaker_start)
            if not id:
                continue
            gender =  sheet.cell_value(r, speaker_start + 1)
            if not gender:
                continue
            print(id, gender)
            id = '{}{}'.format(gender[0], int(id))
            birthdecade = sheet.cell_value(r, speaker_start + 2)
            birthplace = sheet.cell_value(r, speaker_start + 3)
            occupation = sheet.cell_value(r, speaker_start + 4)
            print(id,gender, birthdecade, birthplace, occupation)
            speakers.append({'speaker': id, 'gender':gender, 'birthdecade':birthdecade, 'birthplace':birthplace, 'occupation':occupation})
    with open(new_meta, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=['speaker', 'gender', 'birthdecade', 'birthplace', 'occupation'])
        writer.writeheader()
        for line in speakers:
            writer.writerow(line)

if __name__ == '__main__':
    reorganize_meta_file()
