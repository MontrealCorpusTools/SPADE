import os
import pandas as pd
import re 
import argparse
import numpy as np
import subprocess
import sys 

np.random.seed(1234)
def get_sample(path):
	sib_df = pd.read_csv(path)

	all_corpora = sib_df['corpus']
	corp_freqdict = {c:0 for c in set(all_corpora)}
	data_dict = {c: None for c in set(all_corpora)}
	for c in all_corpora:
		corp_freqdict[c]+=1
	perc = .01
	tot_df = pd.DataFrame()
	corp_freqdict = {c: np.rint(perc * float(v)) for c,v in corp_freqdict.items()}
	for corp,num_samples in corp_freqdict.items():
		data=[]
		sub_frame = sib_df[sib_df.corpus  == corp]

		all_idxs = np.arange(0, sub_frame.shape[0],1)

		chosen_idxs = np.random.choice(all_idxs, size=int(num_samples))
		tot_df = pd.concat([tot_df, sub_frame.iloc[chosen_idxs]])

	return tot_df, set(all_corpora)

# def write_files(df, path_dict):
# 	"""
# 	Parameters
# 	----------
# 	df: pd dataframe
# 		representative sample of original data
# 	path_dict:
# 		dict with corpus name as key and path to textgrids for that corpus as value
# 	"""

# 	desired_info = []
# 	sub_df = df[]

def input_taker(df,locations):
	print("Interactive script for sibilant checks:")
	enter = input("press enter to continue")
	row_idx = 0
	print(enter)
	while enter.strip() is "":
		# get a line from the df
		row = df.iloc[row_idx]
		filename = row["discourse"]
		corpus = row["corpus"].lower()
		print(corpus)
		if corpus == "SOTC":
			split_name = re.split("-", filename)
			outer_dir = "-".join(split_name[0:2])
			inner_dir = "-".join(split_name[0:3])
			tg_path = os.path.join(locations[corpus], outer_dir, inner_dir, filename + ".TextGrid")
			wav_path = os.path.join(locations[corpus], outer_dir, inner_dir, filename + ".wav")
		else:
		# elif corpus == "Raleigh":
			outer_dir = filename[0:6]
			tg_path = os.path.join(locations[corpus], outer_dir, filename + ".TextGrid")
			wav_path = os.path.join(locations[corpus], outer_dir, filename + ".wav")

		zoom_start, zoom_end = row["begin"], row["end"]
		
		path_to_open = os.path.join(os.path.split(os.path.abspath(__file__))[0],  "open_tg.praat")
		# ./sendpraat praat "execute Users/Elias/SPADE/ICECAN/sibilant_script/open_tg.praat
		command = ['./sendpraat', 'praat', '"execute', path_to_open, str(tg_path), str(wav_path), str(zoom_start), str(zoom_end)+ '"']
		print(" ".join(command))
		sys.exit()
		p = subprocess.Popen(command, shell=True)

		p.communicate()
		# open textgrid with wav by subprocess calling praat script with arguments
		row_idx+=1


def get_locations(corpora, location_file):
	"""	
	needs a list of corpora (for checks) and a location file
	where each line is <corpus_name>,<textgrid_location> 
	"""
	with open(location_file) as f1:
		lines = [x.split(",") for x in f1.readlines()]
	location_dict = {x.lower():None for x in corpora}
	for corpus, location in lines:
		try:
			if not os.path.exists(location.strip()):
				print("Error: Location {} does not exist".format(location))
				sys.exit(1)
			location_dict[corpus.lower()] = location.strip()
		except KeyError:
			print("Error: Corpus {} is not in the sibilant dataset".format(corpus))
			sys.exit(1)
	return location_dict



one_perc_df, corpora = get_sample("testsibilants.csv")
just_Ral = one_perc_df[one_perc_df.corpus == "Raleigh"]
loc_dict = get_locations(corpora, "locations.txt")
input_taker(just_Ral, loc_dict)
sys.exit()


print(one_perc_df.shape)