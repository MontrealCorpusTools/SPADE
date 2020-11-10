## Script for batch-running multitaper script on all SPADE corpora
## James Tanner Nov 2020

import subprocess
import re
import os
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("InputDir", help = "Path to the list of sibilant files")
parser.add_argument("SoundDir", help = "Path to the top level of sound files")
parser.add_argument("OutputDir", help = "Path to write out CSVs")
args = parser.parse_args()

## corpora with subdirs
subdirs = ['spade_Buckeye', 'spade_dapp_EnglandLDS', 'spade_dapp_Ireland', 'spade_dapp_Scotland', 
           'spade_dapp_ScotlandNE', 'spade_dapp_Wales', 'spade_DECTE', 'spade_Edinburgh',
           'spade_GlasgowBiD', 'spade_Glaswasian', 'spade_ICE_Sco', 'spade_Irish', 'spade_IViE_Belfast',
           'spade_IViE_Bradford', 'spade_IViE_Cambridge', 'spade_IViE_Cardiff', 'spade_IViE_Dublin',
           'spade_IViE_Leeds', 'spade_IViE_London', 'spade_IViE_Newcastle', 'spade_PAC_Ayr',
           'spade_PEBL', 'spade_PettyHarbour', 'spade_Raleigh', 'spade_SOTC', 'spade_TIMIT']

## corpora with numbers as discourse name
numbers = ["spade_WYRED"]

## corpora that use speaker name instead of discourse
speakers = ['spade_DECTE']

def getCorpusName(file):
    """Extract corpus name from CSV file"""
    corpus = re.search("(spade-.*)_sibilants.csv", file).group(1)

    return corpus

def runMTS(corpus, d = False, n = False, s = False):
    """Call R process to run mts script"""

    inPath = os.path.join(args.InputDir, corpus)
    SoundPath = os.path.join(args.SoundDir, corpus)

    if d:
        subprocess.call(['Rscript', 'generate_mts_measures.r', '-d', inPath, SoundPath, args.OutputDir])
    elif n:
        subprocess.call(['Rscript', 'generate_mts_measures.r', '-n', inPath, SoundPath, args.OutputDir])
    elif s:
        subprocess.call(['Rscript', 'generate_mts_measures.r', '-s', inPath, SoundPath, args.OutputDir])
    else:
        subprocess.call(['Rscript', 'generate_mts_measures.r', inPath, SoundPath, args.OutputDir])

def processFile(file):
    """Get corpus name and run MTS
       script with arguments"""

    if file.endswith("csv"):
        print(file)

        corpus = getCorpusName(file)

        if corpus in subdirs:
            runMTS(corpus, d = True)
        elif corpus in numbers:
            runMTS(corpus, n = True)
        elif corpus in speakers:
            runMTS(corpus, s = True)
        else:
            runMTS(corpus)

## test
list(map(processFile, os.listdir(args.InputDir)))


