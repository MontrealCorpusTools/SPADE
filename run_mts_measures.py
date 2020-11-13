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

## skipped corpora
skipped = []

## corpora with subdirs
subdirs = ['spade-Buckeye', 'spade-dapp-EnglandLDS', 'spade-dapp-Ireland', 'spade-dapp-Scotland', 
           'spade-dapp_ScotlandNE', 'spade-dapp-Wales', 'spade-DECTE', 'spade-Edinburgh',
           'spade-GlasgowBiD', 'spade-Glaswasian', 'spade-ICE_Sco', 'spade-Irish', 'spade-IViE-Belfast',
           'spade-IViE-Bradford', 'spade-IViE-Cambridge', 'spade-IViE-Cardiff', 'spade-IViE-Dublin',
           'spade-IViE-Leeds', 'spade-IViE-London', 'spade-IViE-Newcastle', 'spade-PAC-Ayr',
           'spade-PEBL', 'spade-PettyHarbour', 'spade-Raleigh', 'spade-SOTC', 'spade-TIMIT']

## corpora with numbers as discourse name
numbers = ["spade-WYRED"]

## corpora that use speaker name instead of discourse
speakers = ['spade-DECTE']

def getCorpusName(file):
    """Extract corpus name from CSV file"""
    corpus = re.search("(spade-.*)_sibilants.csv", file).group(1)

    return corpus

def runMTS(corpus, file, flag = []):
    """Call R process to run mts script"""

    inPath = os.path.join(args.InputDir, file)
    SoundPath = os.path.join(args.SoundDir, corpus, "audio_and_transcripts")

    ## command line call
    cmd = ['Rscript', 'generate_mts_measures.r', inPath, SoundPath, args.OutputDir]

    ## insert flags into command line call
    if len(flag) > 0:
        for i, fl in enumerate(flag):
            cmd.insert(i + 2, fl)

    ## make R call
    print(cmd)
    subprocess.call(cmd)

def processFile(file, f = []):
    """Get corpus name and run MTS
       script with arguments"""

    if file.endswith("csv"):

        corpus = getCorpusName(file)

        if corpus in skipped:
            return

        if corpus in subdirs:
            f.append('-d')

        if corpus in numbers:
            f.append('-n')

        if corpus in speakers:
            f.append('-s')

        runMTS(corpus, file, flag = f)

## run over directory
list(map(processFile, os.listdir(args.InputDir)))
