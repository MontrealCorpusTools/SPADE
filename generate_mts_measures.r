# Author:  Patrick Reidy
# Purpose: Demo multitaper spectral analysis for Jane Stuart-Smith.
# Date:    2018-05-23

# Modified by:  Michael Goodale
# Purpose: ISCAN Token import/export tutorial
# Date:    2019-05-23

# modifed by: Jane Stuart-Smith
# Purpose: first of all to create stripped script to produce only a few measures for piloting purposes. Have removed a lot of the explanatory stuff from Pat Reidy for me.  Have recorded tips and wrinkles, futher work to do, plus initial comments for protocol here.
# Date: 2020-04-09

# modified by: James Tanner
# Purpose: process input data as command-line arguments
# Date: 2020-09-29

# modified by: James Tanner
# Purpose: convert to functions
# Data: 2021-03-28

started_at <- date()

library(ggplot2)
library(magrittr)
library(multitaper)
library(tibble)
library(tuneR)
library(doParallel)
library(foreach)
library(argparse)
library(stringr)
library(svMisc)

## Process comamand-line arguments
parser <- ArgumentParser(description = "Generate multitaper sibilant measurements")
parser$add_argument("input_file", help = "CSV file containing sibilants observations to measure")
parser$add_argument("sound_dir", help = "Path to the top-level directory containg the audio files")
parser$add_argument("output_dir", help = "Directory to write the mts-measured CSV file")
parser$add_argument("--directories", "-d", help = "The audio file contains speaker-level subdirectories", action = "store_true", default = FALSE)
parser$add_argument("--numbers", "-n", help = "Speaker names are defined with numbers (integers) instead of letters", action = "store_true", default = FALSE)
parser$add_argument("--speakers", "-s", help = "Use speaker codes for audio file names", action = "store_true", default = FALSE)
args <- parser$parse_args()

# The R files in the ./auxiliary subdirectory of this demo define a handful of
# S4 classes, generics, and methods that wrap functionality from the tuneR and
# multitaper packages.
# You'll need to source the R files in this order because, e.g., definitions
# in later files depend on S4 classes defined in earlier files.
source('./auxiliary/Waveform.R') # For reading .wav files.
source('./auxiliary/Spectrum.R') # Base methods shared by all spectrum-like objects.
source('./auxiliary/Periodogram.R') # For estimating spectra using the periodogram.
source('./auxiliary/DPSS.R') # Windowing functions for multitaper spectra.
source('./auxiliary/Multitaper.R') # For estimating spectra using multitaper method.

# JM: to rebuild most of the Multitaper S4 object for using Pat's measurement functions at a later time:
rebuildMultitaper <- function(token_id, corpus_data, all_multitapers){
    new(Class = 'Multitaper',
        values   = as.numeric(all_multitapers$values[corpus_data$phone_id==token_id,]),
        binWidth = all_multitapers$binWidth,
        nyquist  = all_multitapers$nyquist,
        k        = all_multitapers$k,
        nw       = all_multitapers$nw)
        # tapers   = .dpss)
}

rebuildMultitaperByRow <- function(row, all_multitapers){
    new(Class = 'Multitaper',
        values   = as.numeric(all_multitapers$values[row,]),
        binWidth = all_multitapers$binWidth,
        nyquist  = all_multitapers$nyquist,
        k        = all_multitapers$k,
        nw       = all_multitapers$nw)
        # tapers   = .dpss)
}

get_file_path <- function(corpus_data, row, sound_file_directory, subdirs){

    if (args$speakers){
        sound_file <- paste0(corpus_data[row, "speaker"], '.wav')
    }else if ('sound_file_name'%in%names(corpus_data)){
        sound_file <- paste0(gsub(".WAV", "", corpus_data[row, "sound_file_name"]), '.wav')
    }else if ('recording'%in%names(corpus_data)){
        sound_file <- paste0(corpus_data[row, "recording"], '.wav')
    }else{
        sound_file <- paste0(corpus_data[row, "discourse"], '.wav')
    }
    sound_file <- gsub('.wav.wav','.wav',sound_file) # because some of them already have .wav at the end
    if (subdirs){
       file.path(sound_file_directory, corpus_data[row, "speaker"], sound_file)
    }else{
       file.path(sound_file_directory, sound_file)
    }
}

read_dataset <- function(filepath, sound_dir) {
	## extract corpus name from dataset filename
	cat("File: ", filepath, "\n")
    corpus_name <- str_match(filepath, "([A-Za-z0-9_-]*)\\_sibilants\\.csv")[,2]
    cat("Corpus name:", "\t", corpus_name, "\n")

	# get the directory of the sound file and
	# read in the CSV
    sound_file_directory <- sound_dir
    corpus_data <- read.csv(filepath)

    if (args$numbers){
        corpus_data$discourse <- sprintf("%03d",corpus_data$discourse)
    }
	return(list(corpus_data, corpus_name, sound_file_directory))
}

get_phone_time <- function(data, time, row) {
	t <- data[row, time]
	return(t)
}

# https://stackoverflow.com/questions/7824912/max-and-min-functions-that-are-similar-to-colmeans
colMax <- function (colData) {
    apply(colData, MARGIN=c(2), max)
}

colSD <- function (colData) {
    apply(colData, MARGIN=c(2), sd)
}

parallelized <- TRUE 
n_cores <- 20

measuring <- TRUE

if (measuring){

    ## Get the corpus name from the input file
	dataset = read_dataset(args$input_file, args$sound_dir)
	corpus_data = dataset[[1]]
	corpus_name = dataset[[2]]
	sound_file_directory = dataset[[3]]

    if(parallelized) {
        registerDoParallel(n_cores)
    }else{
        n_cores = 1
    }
    #JM: open the first token to gather information
    file_path <- get_file_path(corpus_data, row=1, sound_file_directory, args$directories)

    begin <- get_phone_time(corpus_data, "phone_begin", 1)
    end <- get_phone_time(corpus_data, "phone_end", 1)
    file_midpoint <- begin + (end-begin) / 2
    
    sock.x <- readWave(filename = file_path, from = file_midpoint - 0.0125, to = file_midpoint + 0.0125, units='seconds')
    sock.x <- downsample(sock.x, 22050)
    sock <- Waveform(sock.x)
    sock_spectrum <- sock %>% Multitaper(k = 8, nw = 4)
    
    #JM: save all the multitaper values
    all_multitapers <- list(values = NULL, 
                            frequencies = seq(from = 0, to = sock_spectrum@nyquist, by = sock_spectrum@binWidth),
                            binWidth = sock_spectrum@binWidth,
                            nyquist = sock_spectrum@nyquist,
                            k = sock_spectrum@k,
                            nw = sock_spectrum@nw)
    n_values <- length(sock_spectrum@values)
    mts_colnames <- paste0('S',1:n_values)

    corpus_data[,mts_colnames] <- NA

    #Split 0:nrows into (roughly) equal sized batches that are in order
    batch_indices <- rep(0:(n_cores-1), each=(nrow(corpus_data) %/% n_cores))
    batch_indices <- c(rep(0, nrow(corpus_data)-length(batch_indices)), batch_indices)

    batches <- split(1:nrow(corpus_data), batch_indices)
    
    # corpus_data <- subset(corpus_data, !discourse %in% c('ntn0290b','ntn0200a','ntn0370b','ntn0240a'))

    corpus_data <- foreach(batch=batches, .combine=rbind) %dopar% {
        corpus_data <- corpus_data[batch, ]
        # print(corpus_data)
        for (row in 1:nrow(corpus_data)){
        # for (row in 1:200){

            cat(round(row/nrow(corpus_data),6), "\r")
            #To use for non-speaker directory corpora, just remove the speaker name and "/" from the paste function here.
            #sound_file <- paste(corpus_data[row, "speaker_name"], "/", corpus_data[row, "sound_file_name"], '.wav', sep="")

            # sound_file <- paste(corpus_data[row, "sound_file_name"], '.wav', sep="")
            #JM: to handle column names of csv files made by sibilant.py:

            file_path <- get_file_path(corpus_data, row, sound_file_directory, args$directories)

            begin <- corpus_data[row, "phone_begin"]
            end <- corpus_data[row, "phone_end"]

            file_midpoint <- begin + (end-begin) / 2

            # print(file_path)
            # print(begin)
            # print(end)
            # print(file_midpoint)

            # Read the contents of the wav file.

        	if(!file.exists(file_path)){
        		next
        	}

            # print('a')
            # print(file_path)
            # print (corpus_data[1,1:23])
            #JM: this seems like a more straightforward way to open and downsample, but I may be misunderstanding why it was originally done differently
            # print (paste0("sock.x <- readWave(filename = ",file_path,", from = ",file_midpoint," - 0.0125, to = ",file_midpoint," + 0.0125, units='seconds')"))
            sock.x <- readWave(filename = file_path, from = file_midpoint - 0.0125, to = file_midpoint + 0.0125, units='seconds')
            # print('a1')
            sock.x <- downsample(sock.x, 22050)
            # print('a2')
            sock <- Waveform(sock.x)
            # print('b')
            
        	#want to run first of all without downsampling. IcE-Can apparently is 44100Hz sampling rate

        	# sock <- Waveform(waveform = file_path, from = file_midpoint - 0.020, to = file_midpoint + 0.020)

        	## this hopefully will downsample for me... NOTE this will also take the 25ms window which is as per K et al.

            #sockb = downsample(socka[length(socka@left)/2+seq(-socka@samp.rate*0.0125,socka@samp.rate*0.0125)], 22050)
            #sockc = Waveform(waveform = sockb)
            #sock = sockc

           #Estimate the spectrum of sock using the multitaper method. no preemphasis or zeropadding.
              sock_spectrum <-
              sock %>%
              #PreEmphasize(alpha = 0.5) %>% # optional
              #ZeroPad(lengthOut = sampleRate(sock)) %>% # again, optional
              Multitaper(k = 8, nw = 4)
              
        # print('c')
    ## measures for pilot1: cog, peak_full, peak_mid

    ## measures intended:
    ## cog: taken across whole range, so lower cutoff 550Hz, as K et al, to nyquist
    ## spread; taken across whole range, so lower cutoff 550Hz, as K et al, to nyquist [not skew and kurtosis ?]
    ## peak_full: across whole range, so lower cutoff 550Hz to nyquist
    ## peak_mid: the mid-range peak (freqM), K et al 2013
    ##peak_adjusted_mid: 2000 - 9000; i.e. edited ranges so that they can capture the actual high peaks of female speakers, and the possible sh productions by some male speakers. The intention is to measure realisations of /s/, which could a) be well-formed [s] but higher freq than assumed by K et al, since these do actually exist in the wild, b) other productions used for /s/, which are needed in order to demonstrate the range of possible, likely, and actual, acoustic realizations of /s/ (and also /sh/) in the wild. This is different from K et al, who seek to capture well-formed /s/, i.e. the acoustics of assumed alveolar fricative [s].
    # ampdiff: ampDM-LMin, which captures difference in amplitude from lowest amp within the low range (550-3000) and highest amp in the mid range (3000-7000), K et al 2013
    ## ampdiff_adjusted: adjusted so mid range is 3000-9000.
    ## slope: from ampLmin to peaksensible rangemid. Need to do more work on script to get this working, before trying out in ISCAN.

    ## [NOT: Leveldiff, which was designed to track differences across the course of /s/, and doesn't mean much on its own - level = soundlevel]

                ## Measures: For description, discussion and justification of measures, see Protocol for sibilants revised 13 May 2020

                # 1. full range peak and COG, where the range is 1000-11000Hz.
                #    This will capture the high PEAK for /s/, and generally capture /sh/ PEAK quite well (with the proviso that there are the odd cases of /sh/ which show a prominence >6000Hz).

                corpus_data[row, "spectral_peak_full"] <- peakHz(sock_spectrum, minHz = 1000, maxHz = 11000)

                corpus_data[row, "spectral_cog"] <- centroid(sock_spectrum, scale = "decibel", minHz = 1000, maxHz=11000)

                # 2. a mid-frequency range peak: which serves for both /s sh/, 2000-7000Hz.
                #    For /sh/ the spectral maximum will generally coincide with the PEAK;
                #    for /s/ the spectral maximum will coincide with the PEAK for some, but not all (female) speakers.
                #    I would be loath to increase the range to >7000Hz, since then this really stops being anything near 'mid-frequency' range.

        # print('d')
                corpus_data[row, "spectral_peak_mid"] <- peakHz(sock_spectrum, minHz = 2000, maxHz = 7000)
                corpus_data[row, "spectral_peak_2k8k"] <- peakHz(sock_spectrum, minHz = 2000, maxHz = 8000)
                corpus_data[row, "spectral_peak_2k9k"] <- peakHz(sock_spectrum, minHz = 2000, maxHz = 9000)

                # 3. spectral peak within the 2000-5000Hz range, as a general sibilant measure. This may capture the peak ~ front cavity resonance.

                corpus_data[row, "spectral_peak_lower_mid"] <- peakHz(sock_spectrum, minHz = 2000, maxHz = 5000)


                # 4. spread/stdev (2nd moment) - full range
                corpus_data[row, "spectral_spread"] <- variance(sock_spectrum, scale = "decibel", minHz = 1000, maxHz= 11000)

                # 5. ampdiff: for s and sh, measured for all sibilants, to be separated out afterwards. s_range assumes anti-resonance <3000; sh_range assumes it's lower. These are pilot measures, to look at, against troughs/peak/PEAKS. Very likely to reformulate this, given that antiresonance can shift quite a lot, by speaker, especially for /s/. Certainly, some speakers have their main antiresonance above 3000Hz in Raleigh.

        # print('e')
                minamp_low_s <- minAmp(sock_spectrum, scale = "dB", minHz = 1000, maxHz = 3000)
                maxamp_mid_s <- maxAmp(sock_spectrum, scale = "dB", minHz= 3000, maxHz=7000)
                corpus_data[row, "spectral_ampdiff_s"] <- maxamp_mid_s - minamp_low_s

                minamp_low_sh <- minAmp(sock_spectrum, scale = "dB", minHz = 1000, maxHz = 2000)
                maxamp_mid_sh <- maxAmp(sock_spectrum, scale = "dB", minHz= 2000, maxHz=6000)
                corpus_data[row, "spectral_ampdiff_sh"] <- maxamp_mid_sh - minamp_low_sh

                ## 6. front slope, low-range (1000-4000Hz). This is again, just for Jane to have a look at. Proper slopes, ending on an appropriate higher upper-bound, relating to speaker peaks, will be calculated from Multitaper spectra, later.

        # print('f')
                spectralSlope <- function(mts, minHz = -Inf, maxHz = Inf) {
                    .indices <- (function(.f) {which(minHz < .f & .f < maxHz)})(frequencies(mts))
                    .freqs <- frequencies(mts)[.indices] %>% (function(.x) {(.x - mean(.x)) / sd(.x)})
                    .values <- ((function(.v) {10 * log10(.v)})(values(mts)))[.indices] %>%
                        (function(.x) {(.x - mean(.x)) / sd(.x)})
                    .spec <- data.frame(x = .freqs, y = .values)
                    .coeffs <- coef(lm(data = .spec, formula = y ~ x))
                    return(coef(lm(data = .spec, formula = y ~ x))[2])
                }

                corpus_data[row, "spectral_lower_slope"] <- spectralSlope(sock_spectrum, minHz = 1000, maxHz = 4000)
                corpus_data[row, "spectral_cog_8k"] <- centroid(sock_spectrum, scale = "decibel", minHz = 1000, maxHz=8000)

        # print('g')
            #JM: store the multitaper
            if (length(sock_spectrum@values) < length(mts_colnames)){
                sock_spectrum@values <- c(sock_spectrum@values, rep(0,length(mts_colnames)-length(sock_spectrum@values)))
                # print (sock_spectrum@values)
            }
            corpus_data[row,mts_colnames] <- sock_spectrum@values
            #JM: how to get frequencies and values out
            # frequencies <- seq(from = 0, to = sock_spectrum@nyquist, by = sock_spectrum@binWidth)
            # values <- sock_spectrum@values
          
        # print('h')  
        }
        corpus_data
    }

    stopImplicitCluster()

    all_multitapers$values <- corpus_data[,mts_colnames]
    corpus_data <- corpus_data[,setdiff(colnames(corpus_data),mts_colnames)]

    write.csv(corpus_data, paste0(args$output_dir, corpus_name,"_mts_sibilants",".csv"))

    save(all_multitapers, file=paste0(args$output_dir, corpus_name,"_all_multitapers",".RData"))
}

finished_at <- date()
print (paste('started', started_at))
print (paste('finished', finished_at))

