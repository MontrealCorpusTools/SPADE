# Author:  Patrick Reidy
# Purpose: Demo multitaper spectral analysis for Jane Stuart-Smith.
# Date:    2018-05-23

# Modified by:  Michael Goodale
# Purpose: ISCAN Token import/export tutorial
# Date:    2019-05-23

# modifed by: Jane Stuart-Smith
# Purpose: first of all to create stripped script to produce only a few measures for piloting purposes. Have removed a lot of the explanatory stuff from Pat Reidy for me.  Have recorded tips and wrinkles, futher work to do, plus initial comments for protocol here.
# Date: 2020-04-09

#NOTE: Depending on the corpus you use, you may have to modify the script.
# This is just the file structure of the corpus itself
# if the corpus has speaker directories, you don't need to do anything
# If the corpus doesn't have speaker directories, you just need to change one line below (details below)

# this is Michael G's - so I will somehow need access to the audio_and_transcripts directories for the SPADE corpora
#sound_file_directory <- "/projects/spade/repo/git/spade-Buckeye/audio_and_transcripts"
## THIS WILL NEED TO BE SORTED OUT or it may just work, let's see.


## editing for now, for spade-tutorial-janess - no speaker directories, just 10 sample sound/TG files.

## NOTES: procedure: I ran the enrichments on the corpus as per tutorials, then ran the specified query in order to provide the input csv file - with location/specification of sibilants within sound files. I did that from ISCAN from laptop. Then I moved that csv file via winscp to the spade-tutorial-janess folder in my home area, put the Rscript in that folder too, and ran it using:
# Rscript scriptname (code in Vanna slack messages)
# This produced the csv of measures, which I moved back to my laptop with winscp, and uploaded to ISCAN; then I reran the query, exported the measures.

## for future:  need to tidy up: move script and .csv input file to corpus_data/enrichments (i.e. away from the audio_and_transcripts folder)
## I need to check script works ok from there, pointing to the right A+T folder
## it's crucial that if there are already measures/labels in ISCAN stored from previous work, the new measures have NEW NAMES!
## I need to run pilot script on sibilants from soundfiles that don't have 3kHz range limit - so I can check the measures against Praat view of soundfile. DoubleTalk could work, or a couple of files from DT
## need to test with the downsampling option, to see if that worked. Could ?write downsampled chunk as a wav file, to check, within the script

started_at <- date()

library(ggplot2)
library(magrittr)
library(multitaper)
library(tibble)
library(tuneR)
library(doParallel)
library(foreach)

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

parallelized <- TRUE 
n_cores <- 20

measuring <- TRUE
plotting <- TRUE


sound_file_directories <- list(Buckeye='/projects/spade/repo/git/spade-Buckeye/audio_and_transcripts', 
#                                SantaBarbara='/projects/spade/repo/git/spade-SantaBarbara/audio_and_transcripts',
#                                SCOTS='/projects/spade/repo/git/spade-SCOTS/audio_and_transcripts', 
#                                SOTC='/projects/spade/repo/git/spade-SOTC/audio_and_transcripts', 
#                                CanadianPrairies='/projects/spade/repo/git/spade-Canadian-Prairies/audio_and_transcripts', 
#                                CORAAL='/projects/spade/repo/git/spade-CORAAL/audio_and_transcripts', 
#                                Edinburgh='/projects/spade/repo/git/spade-Edinburgh/audio_and_transcripts', 
#                                Hastings='/projects/spade/repo/git/spade-Hastings/audio_and_transcripts', 
#                                ModernRP='/projects/spade/repo/git/spade-ModernRP/audio_and_transcripts', 
#                                Raleigh='/projects/spade/repo/git/spade-Raleigh/audio_and_transcripts') 

# sound_file_directories[['dapp-EnglandRP']] <- '/projects/spade/repo/git/spade-dapp-EnglandRP/audio_and_transcripts'
# sound_file_directories[['WYRED']] <- '/projects/spade/repo/git/spade-WYRED/audio_and_transcripts'
# sound_file_directories[['IViE-Liverpool']] <- '/projects/spade/repo/git/spade-IViE-Liverpool/audio_and_transcripts'


corpus_data_file_paths <- list(Buckeye='/projects/spade/data/derived-measures/spade-Buckeye_sibilants.csv', 
#                                SantaBarbara='/projects/spade/data/derived-measures/spade-SantaBarbara_sibilants.csv',
#                                SCOTS='/projects/spade/data/derived-measures/spade-SCOTS_sibilants.csv', 
#                                SOTC='/projects/spade/datasets/datasets_sibilants/spade-SOTC_sibilants.csv', 
#                                CanadianPrairies='/projects/spade/datasets/datasets_sibilants/spade-Canadian-Prairies_sibilants.csv', 
#                                CORAAL='/projects/spade/datasets/datasets_sibilants/spade-CORAAL_sibilants.csv', 
#                                Edinburgh='/projects/spade/data/derived-measures/spade-Edinburgh_sibilants.csv', 
#                                Hastings='/projects/spade/data/derived-measures/spade-Hastings_sibilants.csv', 
#                                ModernRP='/projects/spade/datasets/datasets_sibilants/spade-ModernRP_sibilants.csv', 
#                                Raleigh='/projects/spade/datasets/datasets_sibilants/spade-Raleigh_sibilants.csv') 

# corpus_data_file_paths[['dapp-EnglandRP']] <- '/projects/spade/datasets/datasets_sibilants/spade-dapp-EnglandRP_sibilants.csv'
# corpus_data_file_paths[['WYRED']] <- '/projects/spade/datasets/datasets_sibilants/spade-WYRED_sibilants.csv'
# corpus_data_file_paths[['IViE-Liverpool']] <- '/projects/spade/datasets/datasets_sibilants/spade-IViE-Liverpool_sibilants.csv'

corpora_with_subdirs <- c('Buckeye', 'IViE-Liverpool')

if (measuring){
    for (corpus_name in names(corpus_data_file_paths)){
    # for (corpus_name in c('DNEED')){
        sound_file_directory <- sound_file_directories[[corpus_name]]
        corpus_data <- read.csv(corpus_data_file_paths[[corpus_name]])

        corpus_data$discourse <- sprintf("%03d",corpus_data$discourse)

        corpus_data <- subset(corpus_data, !discourse%in%c('041'))
        if(parallelized) {
            registerDoParallel(n_cores)
        }else{
            n_cores = 1
        }
        #JM: open the first token to gather information
        if ('sound_file_name'%in%names(corpus_data)){
            sound_file <- paste0(corpus_data[1, "sound_file_name"], '.wav')
        }else{
            sound_file <- paste0(corpus_data[1, "discourse"], '.wav')
        }
        if (corpus_name%in%corpora_with_subdirs){
           file_path <- file.path(sound_file_directory, corpus_data[1, "speaker"], sound_file)
        }else{
           file_path <- file.path(sound_file_directory, sound_file)
        }
        begin <- corpus_data[1, "phone_begin"]
        end <- corpus_data[1, "phone_end"]
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
        
        corpus_data <- foreach(batch=batches, .combine=rbind) %dopar% {
            corpus_data <- corpus_data[batch, ]
            # print(corpus_data)
            for (row in 1:nrow(corpus_data)){
            # for (row in 1:200){
                print (round(row/nrow(corpus_data),6))
                #To use for non-speaker directory corpora, just remove the speaker name and "/" from the paste function here.
                #sound_file <- paste(corpus_data[row, "speaker_name"], "/", corpus_data[row, "sound_file_name"], '.wav', sep="")

                # sound_file <- paste(corpus_data[row, "sound_file_name"], '.wav', sep="")
                #JM: to handle column names of csv files made by sibilant.py:
                if ('sound_file_name'%in%names(corpus_data)){
                    sound_file <- paste0(corpus_data[row, "sound_file_name"], '.wav')
                }else{
                    sound_file <- paste0(corpus_data[row, "discourse"], '.wav')
                }
                
                begin <- corpus_data[row, "phone_begin"]
                end <- corpus_data[row, "phone_end"]

                # print(file_path)
                # print(begin)
                # print(end)

                file_midpoint <- begin + (end-begin) / 2
                # Read the contents of the wav file.
            if (corpus_name%in%corpora_with_subdirs){
        	   file_path <- file.path(sound_file_directory, corpus_data[row, "speaker"], sound_file)
            }else{
               file_path <- file.path(sound_file_directory, sound_file)
            }
        	if(!file.exists(file_path)){
        		next
        	}

            # print('a')
            # print(file_path)
            #JM: this seems like a more straightforward way to open and downsample, but I may be misunderstanding why it was originally done differently
            sock.x <- readWave(filename = file_path, from = file_midpoint - 0.0125, to = file_midpoint + 0.0125, units='seconds')
            sock.x <- downsample(sock.x, 22050)
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

        write.csv(corpus_data, paste0(corpus_name,"_spectral_sibilants",".csv"))

        save(all_multitapers, file=paste0(corpus_name,"_all_multitapers",".RData"))
    }
}


corpus_phone_sets <- list(Ss=c("Edinburgh", "GlasgowBiD", "Irish", "SCOTS", "SOTC", 'dapp-EnglandRP', 'IViE-Liverpool',
                               'dapp_EnglandLDS', 'dapp_Ireland', 'dapp_Scotland', 'dapp_ScotlandNE', 'dapp_Wales',     #these are newly added
                               'IViE_Belfast', 'IViE_Bradford', 'IViE_Cambridge', 'IViE_Cardiff', 'IViE_Dublin', 'IViE_Leeds', 'IViE_London', 'IViE_Newcastle'),   #these are newly added
                          ssh=c("Buckeye"),
                          SSH=c("CORAAL", "ModernRP", "SantaBarbara", "ICE-Can", "CanadianPrairies", "DyViS", "NorthWales", "Raleigh", "Sunset", "WYRED",
                                'Doubletalk', 'NEngs_Derby'))  #these are newly added

if(file.exists('sibilant_speakers_to_exclude.csv')){
    speakers_to_exclude <- read.csv('sibilant_speakers_to_exclude.csv')
}else{
    speakers_to_exclude <- data.frame(corpus='x', speaker='x', reason='x')
}

#JM: Now make plots
plotted_at <- date()
if (plotting){

    speaker_ratings <- c()

    delta <- function(y) c(0,diff(y))

    find_extrema <- function(y){
        extrema <- c(diff(delta(y) / abs(delta(y))), 0)
        extrema[is.na(extrema)] <- 0
        -extrema/2
    }


    for (corpus_name in names(corpus_data_file_paths)){

        # mts_path <- '/projects/spade/datasets/datasets_multitaper_sibilants'
        # mts_path <- '/home/jeff/SPADE/sibilants/datasets_multitaper_sibilants'
        mts_path <- '.'

        target_phones_non_ipa <- c('s','S','sh','SH')
        target_phones <- c('s','ʃ')

        load(file.path(mts_path,paste0(corpus_name,"_all_multitapers",".RData")))
        corpus_data <- read.csv(file.path(mts_path,paste0(corpus_name,"_spectral_sibilants",".csv")))

        if (grepl('dapp',corpus_name)){
            # corpus_data <- corpus_data[,colnames(corpus_data)!='speaker']
            # corpus_data <- merge(corpus_data, dapp_speaker_discourse)
            corpus_data$speaker <- corpus_data$uid
        }

        # excluding excluded speakers
        corpus_speakers_to_exclude <- subset(speakers_to_exclude, corpus==corpus_name)
        all_multitapers$values <- all_multitapers$values[!corpus_data$speaker%in%corpus_speakers_to_exclude$speaker,]
        corpus_data <- corpus_data[!corpus_data$speaker%in%corpus_speakers_to_exclude$speaker,]

        library(plyr)
        library(vioplot)

        corpus_summary <- ddply(subset(corpus_data, phone_label%in%target_phones_non_ipa), .(speaker, phone_label), summarize, 
            spectral_peak_mid=mean(spectral_peak_mid))
        corpus_summary$phone_label <- factor(corpus_summary$phone_label)
        corpus_summary$phone_label_ipa <- corpus_summary$phone_label

        if (corpus_name%in%corpus_phone_sets[['Ss']]){
            levels(corpus_summary$phone_label_ipa) <- gsub('S','ʃ',levels(corpus_summary$phone_label_ipa))
        }else if(corpus_name%in%corpus_phone_sets[['ssh']]){
            levels(corpus_summary$phone_label_ipa) <- gsub('sh','ʃ',levels(corpus_summary$phone_label_ipa))
        }else{
            levels(corpus_summary$phone_label_ipa) <- gsub('SH','ʃ',levels(corpus_summary$phone_label_ipa))
            levels(corpus_summary$phone_label_ipa) <- gsub('S','s',levels(corpus_summary$phone_label_ipa))
        }

        corpus_summary$phone_label_ipa <- relevel(corpus_summary$phone_label_ipa, 's')

        corpus_summary$peak_of_means <- NA

        # sv <- subvals[1:5,1:3]
        # xyz <- function(x) 10*log10(x/max(x))
        # xyz(sv)

        corpus_data$phone_label_ipa <- corpus_data$phone_label
        if (corpus_name%in%corpus_phone_sets[['Ss']]){
            levels(corpus_data$phone_label_ipa) <- gsub('S','ʃ',levels(corpus_data$phone_label_ipa))
        }else if(corpus_name%in%corpus_phone_sets[['ssh']]){
            levels(corpus_data$phone_label_ipa) <- gsub('sh','ʃ',levels(corpus_data$phone_label_ipa))
        }else{
            levels(corpus_data$phone_label_ipa) <- gsub('SH','ʃ',levels(corpus_data$phone_label_ipa))
            levels(corpus_data$phone_label_ipa) <- gsub('S','s',levels(corpus_data$phone_label_ipa))
        }
        
        corpus_data$phone_label_ipa <- relevel(corpus_data$phone_label_ipa, 's')

        # for (row in which(!is.na(corpus_data$spectral_peak_full))){
        #     sock_spectrum <- rebuildMultitaperByRow(row, all_multitapers)
        #     corpus_data[row, "spectral_cog_8k"] <- centroid(sock_spectrum, scale = "decibel", minHz = 1000, maxHz=8000)
        # }

        cairo_pdf(paste0(corpus_name,'_all_mts_test_plot2','.pdf'), h=9, w=7, onefile=T) 
        
        layout.matrix <- matrix(c(1, 2, 3, 1, 2, 4, 1, 2, 5), nrow = 3, ncol = 3)
        layout(mat = layout.matrix, heights = c(1.5, 1.5, 1), widths = c(1, 2, 1)) 

        allcolmeans <- c()
        includedspeakernames <- c()
        for (sp in unique(corpus_data$speaker)){
            subdata <- corpus_data[corpus_data$speaker==sp & corpus_data$phone_label_ipa%in%c('s','ʃ'),]
            subvals <- all_multitapers$values[corpus_data$speaker==sp & corpus_data$phone_label_ipa%in%c('s','ʃ'),]
            
            freqs <- all_multitapers$frequencies
            print(c(corpus_name,sp))
            if (sum(corpus_data$speaker==sp)>1){
                subamps <- t(apply(subvals, 1, function(x) 10*log10(x/max(x))))
                # subamps <- subvals
            }
            main = paste0(sp, ' ', subdata$gender[1], subdata$sex[1], ' ', subdata$age[1], subdata$birthyear[1])

            if(sum(!is.na(subamps))){
                if (-Inf %in% subamps){
                    ylim <- range(as.numeric(gsub(-Inf,NA,subamps)),na.rm=T)
                }else{
                    ylim <- range(subamps,na.rm=T)
                }
            }else{
                ylim <- c(-60,0) # This is for SantaBarbara speakers with only NAs
            }

            # if (nrow(subdata)){
            # if (sum(!is.na(subdata$cog))){  # This is for SantaBarbara speakers with only NAs
            if (sum(!is.na(subdata$spectral_peak_full))){  # This is temporary, to get partial pdfs
                plot(0, 0, type='n', xlab='Frequency (Hz)', ylab='Amplitude (dB)', xlim=range(freqs), ylim=ylim, main=main)
            
                if (sum(corpus_data$speaker==sp)==1){ 
                    subamps <- 10*log10(subvals/max(subvals))
                    points(freqs, subamps, type='l', col=c(rgb(c(1,0),0,c(0,1),0.1))[as.numeric(subdata[row,'phone_label_ipa'])])
                }else{
                    for (row in 1:nrow(subdata)){
                        points(freqs, subamps[row,], type='l', col=c(rgb(c(1,0),0,c(0,1),0.1))[as.numeric(subdata[row,'phone_label_ipa'])])
                    }
                    for (i in 1:2){
                        ph <- target_phones[i]
                        phoneamps <- subamps[subdata$phone_label_ipa==ph,]

            
                        if (sum(subdata$phone_label_ipa==ph)>1){
                            meanamps <- colMeans(phoneamps)
                        }else{
                            meanamps <- phoneamps                    
                        }
                        if(sum(subdata$phone_label_ipa==ph)){
                            freqs_2k7k <- freqs[freqs>=2000&freqs<=7000]
                            meanamps_2k7k <- meanamps[freqs>=2000&freqs<=7000]                    
                            peak_of_means <- freqs_2k7k[which(meanamps_2k7k==max(meanamps_2k7k))[1]]
                            mean_of_peaks <- mean(subdata[subdata$phone_label_ipa==ph,"spectral_peak_mid"])
                            corpus_summary[corpus_summary$speaker==sp&corpus_summary$phone_label_ipa==ph,'peak_of_means'] <- peak_of_means
                            points(freqs, meanamps, type='l', col=c(rgb(c(0.4,0),0,c(0,0.6),1))[i], lwd=3)
                            abline(v=c(mean_of_peaks, peak_of_means), lty=c(1,2), col=c(rgb(c(0.4,0),0,c(0,0.6),1))[i], lwd=3)
                        }else{
                            corpus_summary[corpus_summary$speaker==sp&corpus_summary$phone_label_ipa==ph,'peak_of_means'] <- NA
                        }
                    }
                }
            
                legend('bottomleft',c('mean of peaks','peak of means'), lty=c(1,2), lwd=3)
                legend('bottomright',c('s','ʃ'), col=c(rgb(c(0.4,0),0,c(0,0.6),1)), lwd=3)

                if ('s'%in%subdata$phone_label_ipa & sum(!is.na(subdata$cog))){
                    if (sum(subdata$phone_label_ipa=='s')>1){
                        allcolmeans <- rbind(allcolmeans, colMeans(subamps[subdata$phone_label_ipa=='s',]))
                    }else{
                        allcolmeans <- rbind(allcolmeans, subamps[subdata$phone_label_ipa=='s',])                        
                    }
                    includedspeakernames <- c(includedspeakernames, sp)
                }
                # print('xxx')
                if (length(intersect(c('s','ʃ'),subdata$phone_label_ipa))>1 & sum(!is.na(subdata$cog))){
                    # x <- acf(as.numeric(colMeans(subamps)), lag.max=50, plot=F)
                    # xlm <- lm(x$acf ~ x$lag)
                    # plot(x$lag, x$acf, type='l', col='red', ylim=c(-1,1))
                    # points(coef(xlm)[1] + x$lag*coef(xlm)[2], type='l', col='green')
                    # points(residuals(xlm), type='l', col='blue')
                    # legend('topright', c('autocorrelation', 'lm fit', 'residuals'), lty=1, col=c('red','green','blue'))
                    # print('x0')
                    vioplot(subdata[subdata$phone_label_ipa%in%c('s'),'spectral_peak_full'], 
                            subdata[subdata$phone_label_ipa%in%c('ʃ'),'spectral_peak_full'],
                            # subdata[subdata$phone_label_ipa%in%c('s'),'spectral_peak_mid'], 
                            # subdata[subdata$phone_label_ipa%in%c('ʃ'),'spectral_peak_mid'],
                            subdata[subdata$phone_label_ipa%in%c('s'),'spectral_peak_2k8k'], 
                            subdata[subdata$phone_label_ipa%in%c('ʃ'),'spectral_peak_2k8k'],
                            subdata[subdata$phone_label_ipa%in%c('s'),'spectral_peak_2k9k'], 
                            subdata[subdata$phone_label_ipa%in%c('ʃ'),'spectral_peak_2k9k'],
                            subdata[subdata$phone_label_ipa%in%c('s'),'spectral_cog'], 
                            subdata[subdata$phone_label_ipa%in%c('ʃ'),'spectral_cog'],
                            subdata[subdata$phone_label_ipa%in%c('s'),'spectral_cog_8k'], 
                            subdata[subdata$phone_label_ipa%in%c('ʃ'),'spectral_cog_8k'],
                            # subdata[subdata$phone_label_ipa%in%c('s'),'spectral_peak_lower_mid'], 
                            # subdata[subdata$phone_label_ipa%in%c('ʃ'),'spectral_peak_lower_mid'],
                            horizontal=T, las=1, ylab='Frequency (Hz)', main = 'peak measurements',
                            ylim=range(freqs), 
                            col=rep(c(rgb(c(1,0),0,c(0,1),0.5)),5),
                            border=rep(c(rgb(c(0.4,0),0,c(0,0.6),1)),5),
                            names=rep(c('s','ʃ'),5))
                    text(rep(1500,5), 2*(1:5)-0.5,labels=c('spectral_peak_full','spectral_peak_2k8k','spectral_peak_2k9k','spectral_cog','spectral_cog_8k'))
# print('x1')
                    vioplot(subdata[subdata$phone_label_ipa%in%c('s'),'spectral_spread'], 
                            subdata[subdata$phone_label_ipa%in%c('ʃ'),'spectral_spread'],
                            main = 'spectral spread',
                            ylim=c(0,13000000), 
                            col=rep(c(rgb(c(1,0),0,c(0,1),0.5)),1),
                            border=rep(c(rgb(c(0.4,0),0,c(0,0.6),1)),1),
                            names=c('s','ʃ'))
                    vioplot(subdata[subdata$phone_label_ipa%in%c('s'),'spectral_ampdiff_s'], 
                            subdata[subdata$phone_label_ipa%in%c('ʃ'),'spectral_ampdiff_s'],
                            subdata[subdata$phone_label_ipa%in%c('s'),'spectral_ampdiff_sh'], 
                            subdata[subdata$phone_label_ipa%in%c('ʃ'),'spectral_ampdiff_sh'],
                            main = 'spectral ampdiff s & sh',
                            ylim=c(-10,60), 
                            col=rep(c(rgb(c(1,0),0,c(0,1),0.5)),2),
                            border=rep(c(rgb(c(0.4,0),0,c(0,0.6),1)),2),
                            names=rep(c('s','ʃ'),2))
                    vioplot(subdata[subdata$phone_label_ipa%in%c('s'),'spectral_lower_slope'], 
                            subdata[subdata$phone_label_ipa%in%c('ʃ'),'spectral_lower_slope'],
                            main = 'spectral lower slope',
                            ylim=c(-1,1), 
                            col=rep(c(rgb(c(1,0),0,c(0,1),0.5)),1),
                            border=rep(c(rgb(c(0.4,0),0,c(0,0.6),1)),1),
                            names=c('s','ʃ'))

                }else{
                    for (pp in 1:4) plot(0,0,type='n',axes=F,xlab='',ylab='')
                }
            }
        }
                # print('yyy')
        dev.off()
        cairo_pdf(paste0(corpus_name,'_compare_peak_measures','.pdf'), h=6, w=6, onefile=T)  
        plot(corpus_summary$spectral_peak_mid, corpus_summary$peak_of_means, xlab='mean of peaks', ylab='peak of means', 
             col=c(rgb(c(0.7,0),0,c(0,0.7),1))[as.numeric(corpus_summary[,'phone_label_ipa'])], pch=19)
        legend('bottomright',c('s','ʃ'), col=c(rgb(c(0.7,0),0,c(0,0.7),1)), pch=19)
        boxplot(spectral_peak_mid~phone_label_ipa, corpus_summary, ylab='mean of peaks')
        boxplot(peak_of_means~phone_label_ipa, corpus_summary, ylab='peak of means')
        dev.off()

        row.names(allcolmeans) <- includedspeakernames
        allcolmeans[allcolmeans==-Inf] <- NA


        cairo_pdf(paste0(corpus_name,'_speaker_rating','.pdf'), onefile=T)
        for (sp in rownames(allcolmeans)){  
            sp_colmeans <- allcolmeans[sp,]  
            x <- acf(as.numeric(sp_colmeans), lag.max=50, plot=F, na.action=na.pass)
            xlm <- lm(x$acf ~ x$lag)

            print(sp)
            res_maxima <- which(find_extrema(residuals(xlm))==1)
            res_minima <- which(find_extrema(residuals(xlm))==-1)

            comb_filter_badness <- 0
            first_max <- NA
            if (length(res_minima)){
                first_min <- min(res_minima)
                if (length(res_maxima[res_maxima>first_min])){
                    first_max <- min(res_maxima[res_maxima>first_min])
                    comb_filter_badness <- diff(residuals(xlm)[c(first_min,first_max)])
                }
            }
            
            acf_mean_res <- mean(abs(residuals(xlm)))

            ncols <- length(sp_colmeans)
            dynamic_range <- diff(range(sp_colmeans[26:ncols], na.rm=T))
            cutoff_bin_10 <- ncols
            for (mtsbin in 2:ncols){
                if (diff(range(sp_colmeans[mtsbin:ncols], na.rm=T)) < 0.2*dynamic_range){
                    cutoff_bin_20 <- mtsbin
                    break
                }
            }
            cutoff_freq_20 <- (cutoff_bin_20-0.5)*all_multitapers$binWidth

            speaker_ratings <- rbind(speaker_ratings, data.frame(corpus=corpus_name, speaker=sp, 
                                                                 comb_filter_badness=comb_filter_badness, 
                                                                 acf_mean_res=acf_mean_res, 
                                                                 cutoff_freq_20=cutoff_freq_20))
            plot(x$lag, x$acf, type='l', col='red', ylim=c(-1,1), main=paste(sp, round(comb_filter_badness,3),round(acf_mean_res,3), round(cutoff_freq_20),'Hz'))
            points(coef(xlm)[1] + x$lag*coef(xlm)[2], type='l', col='green')
            points(x$lag, residuals(xlm), type='l', col='blue')
            points(x$lag[first_max], residuals(xlm)[first_max], col='blue')
                    legend('topright', c('autocorrelation', 'lm fit', 'residuals'), lty=1, col=c('red','green','blue'))
        }
        corpus_speaker_ratings <- subset(speaker_ratings, corpus==corpus_name)
        write.csv(corpus_speaker_ratings, paste0(corpus_name,"_speaker_ratings",".csv"), row.names=F)
        # write.csv(corpus_data, paste0(corpus_name,"_spectral_sibilants_cog_8k",".csv"), row.names=F)
        plot(corpus_speaker_ratings$comb_filter_badness, corpus_speaker_ratings$cutoff_freq_20, type='n')
        text(corpus_speaker_ratings$comb_filter_badness, corpus_speaker_ratings$cutoff_freq_20, label=corpus_speaker_ratings$speaker)


        dev.off()

    }

}


## peak from 2000 - 9000 Hz, freqM adapted given inspection of Glasgow data, where top of peak range was too low for female peaks > 8000Hz, and too high for /s/, presumably produced as /sh/ by Glasgow male
#corpus_data[row, "spectral_peak_midjss"] <- peakHz(sock_spectrum, minHz = 2000, maxHz = 9000)
#corpus_data[row, "spectral_centroid_midjss"] <- centroid(sock_spectrum, scale = "decibel", minHz = 2000, maxHz=9000)
# skew = skewness(sock_spectrum, scale = "decibel", minHz = 550, maxHz=nyquist(sock_spectrum))
# kurtosis = kurtosis(sock_spectrum, scale = "decibel", minHz = 550, maxHz=nyquist(sock_spectrum))


finished_at <- date()
print (paste('started', started_at))
print (paste('started plotting', plotted_at))
print (paste('finished', finished_at))
        

cairo_pdf(paste0('speaker_rating_','all','.pdf'), onefile=T, height=6, width=12)
plot(speaker_ratings$comb_filter_badness, speaker_ratings$cutoff_freq_20, type='n', xlim=c(-0.05,0.4))
text(speaker_ratings$comb_filter_badness, speaker_ratings$cutoff_freq_20, label=speaker_ratings$speaker)

boxplot(comb_filter_badness ~ corpus, speaker_ratings)
boxplot(cutoff_freq_20 ~ corpus, speaker_ratings)
dev.off()

write.csv(speaker_ratings, paste0("speaker_ratings",".csv"), row.names=F)


# data <- read.csv('datasets_multitaper_sibilants/ICE-Can_spectral_sibilants.csv')
# included_discourses <- gsub('_K','',paste(read.csv('ice_can_useable_sib_files.csv')[,1]))
# unique(subset(data, !discourse%in%included_discourses)$speaker)

# unique(data$speaker)
