import os
import pandas as pd
import re 
import argparse
import numpy as np
from subprocess import Popen, PIPE
import sys 
import platform

np.random.seed(1234)

CORPUS_LIST = ["SB_West", "Raleigh"]

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
		if corpus.lower() == "sotc":
			split_name = re.split("-", filename)
			outer_dir = "-".join(split_name[0:2])
			inner_dir = "-".join(split_name[0:3])
			tg_path = os.path.join(locations[corpus], outer_dir, inner_dir, filename + ".TextGrid")
			wav_path = os.path.join(locations[corpus], outer_dir, inner_dir, filename + ".wav")
		elif corpus.lower() == "raleigh":
			outer_dir = filename[0:6]
			tg_path = os.path.join(locations[corpus], outer_dir, filename + ".TextGrid")
			wav_path = os.path.join(locations[corpus], outer_dir, filename + ".wav")
		elif corpus.lower() == "sb_west":
			tg_path = os.path.join(locations[corpus], filename + ".TextGrid")
			wav_path = os.path.join(locations[corpus], filename + ".wav")
		else:
			print("Error: Corpus {} not implemented".format(corpus))
			sys.exit()

		zoom_start, zoom_end = row["begin"], row["end"]
		cog, peak, slope, spread = row["cog"], row["peak"], row["slope"], row["spread"]
		
		path_to_open = os.path.join(os.path.split(os.path.abspath(__file__))[0],  "open_2.praat")
	
		quote_str = "execute {} {} {} {} {} {} {} {} {}".format(path_to_open, 
																tg_path, wav_path, 
																zoom_start,
																 zoom_end, 
																 cog, peak,
																  slope,
																   spread)

		if platform.system() == "Darwin":
			cmd = ["./sendpraat", "praat", quote_str]
		else:
			cmd = ["sendpraat.exe", "praat", quote_str]
		# print(quote_str)
		with Popen(cmd, stdout=PIPE, stderr=PIPE, stdin=PIPE) as p:
			try:
				text = str(p.stdout.read().decode('latin'))
				err = str(p.stderr.read().decode('latin'))
			except UnicodeDecodeError:
				print(p.stdout.read())
				print(p.stderr.read())

		enter = input("press enter to continue")
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
sub_df = one_perc_df[one_perc_df.corpus.isin(CORPUS_LIST)]
loc_dict = get_locations(corpora, "locations.txt")
input_taker(sub_df, loc_dict)

print(one_perc_df.shape)