import os
import argparse
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("corpusdir", help = "Path to the directory containing corpus directories")
parser.add_argument("script", help = "name of the script to be run")
args = parser.parse_args()

## lists of corpora to skip
## and failed to run
skipped = []
failed = []

## first check that the script exists
assert(os.path.isfile(args.script), "{} should be a script that exists".format(args.script))

## loop through files in the directory
for corpus in os.listdir(args.corpusdir):
    ## check if the file is actually a directory since that is the expected format for the
    ## analysis scripts
    if os.path.isdir(corpus):
        if corpus in skipped:
            continue
        try:
            print("Processing {}".format(corpus))
            ## first reset the corpus
            subprocess.call(['python', 'reset_database.py', corpus])

            ## run the script on the corpus
            subprocess.call(['python', args.script, corpus, "-s"])

        except:
            failed.append(corpus)
            continue
print("Complete!")
print("Following corpora were not run: {}" failed)
