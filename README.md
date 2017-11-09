# SPADE

Basic setup
===========

Linux (Ubuntu is used as the example) is the recommended system for setting up and running
analysis scripts.  Windows 10 can use the Linux Subsystem.

Setting up Python

1. Install Miniconda (https://conda.io/miniconda.html)
2. Create polyglot environment (`conda create -n polyglot python=3.6 numpy scipy`)
3. Activate polyglot environment (Mac/Linux: `source activate polyglot`, Windows: `activate polyglot`)
4. Install PolyglotDB (`pip install polyglotdb pyyaml`)

Ensure Praat is on the path

1. Download Praat if necessary (http://www.fon.hum.uva.nl/praat/download_linux.html, barren edition recommended, rename to praat)
2. The command `which praat` should point to the barren edition downloaded.


Setting up Polyglot-server
==========================

Follow instructions here: http://polyglot-server.readthedocs.io/en/latest/getting_started.html

Use local instance

Follow instructions here: http://polyglotdb.readthedocs.io/en/latest/getting_started.html#set-up-local-database

Running analysis scripts
========================

All meta information about a corpus is stored in YAML files.  These YAML files specify where the corpus is located on your computer, where any enrichment information (from unisyn, or speaker CSV files), and necessary sets of segments for particular analyses (i.e., what are vowels, what are any other syllabic segments, what are the sibilant segments to analyze).

Using Raleigh as example

1. Clone this repo (`git clone https://github.com/MontrealCorpusTools/SPADE.git`) or download (https://github.com/MontrealCorpusTools/SPADE/archive/master.zip)
2. Modify YAML config files to specify correct directories for corpus (see, e.g., Raleigh.yaml in the Raleigh directory), and for `unisyn_spade` repo (see https://github.com/mlml/unisyn_spade)
   for the csv files)
3. In temerminal, `cd /path/to/SPADE`
4. Run formant analysis script (`python formant.py Raleigh`)
5. Run sibilant analysis script (`python sibilant.py Raleigh`)

Running analysis scripts on a new corpus
========================================

1. Make a new directory for the new corpus
2. Create a new yaml file with the same name
3. Populate the fields (corpus_directory, input_format, dialect_code, unisyn_spade_directory, speaker_enrichment_file, speakers, vowel_inventory, stressed_vowels, sibilant_segments)
4. Run as above

Issues
======

If any issues are encountered, first try upgrading the PolyglotDB package (`pip install -U polyglotdb`).

If this does not solve the problem, or if no update is available, please see the Polyglot-users forum (https://groups.google.com/forum/#!forum/polyglot-users)
and post a new question if the issue has not already been addressed.
