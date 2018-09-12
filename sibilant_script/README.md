# Instructions on how to use interactive script

## prerequisites
Python 3.5 and praat are required to run this script. The current version assumes that OsX is running, but this can be changed. Using a virtualenv is recommended; an easy way to set up an environment is by installing and using [Miniconda](https://conda.io/miniconda.html). 

To use the script, the libraries in requirements.txt need to be installed. This can be done by inputting
	`pip install -r requirements.txt`

The testsibilants.csv file should be in the same directory as the script. 

## current functionality
Right now, the script works for the following corpora: SB_West, SOTC, and Raleigh

## How to:
1. Edit the location file
	- the format should be <CORPUS_NAME>,<PATH_TO_CORPUS>
	- the path should be an absolute path
	- examples can be found in the "location_example.txt" file
2. Open the Praat application
	- praat needs to be running already for the script to work
3. run the script 
	- input `python superscript.py` into the command line 
4. step through the interactive script
	- in the command line, a prompt will appear to press enter. Each time you press enter in the command line, a new row will be read from the testsibilants.csv file, which corresponds to a new sibilant. Three Praat windows should open. Note that opening the Praat windows may take a few seconds. 

## Adding new corpora
To add support for new corpora (in case you have them in textgrid format), two changes need to be made: 
1. add their locations to the `locations.txt` file
2. add their names to `CORPUS_LIST` list at line 11 of `superscript.py`


